import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/ksa_api_service.dart';
import '../theme/app_theme.dart';
import 'in_app_browser_screen.dart';

enum _Role { user, assistant }

enum _Phase { off, idle, listening, thinking, speaking }

class _Turn {
  _Turn({
    required this.role,
    required this.text,
    this.sources = const [],
    this.pending = false,
    this.failed = false,
  });

  final _Role role;
  String text;
  List<String> sources;
  bool pending;
  bool failed;
}

const _topics = [
  ('Iqama and Absher', 'How do I renew my Iqama on Absher?'),
  ('Exit re-entry and final exit', 'How does exit re-entry work?'),
  ('Labour law and Qiwa', 'How does a Qiwa sponsorship transfer work?'),
  ('Ejar rentals', 'How do I register an Ejar contract?'),
  ('Balady licences', 'How do I apply for a Balady licence?'),
  (
    'Water (NWC)',
    'Can I order a water tanker from NWC? Official website and phone number?',
  ),
  (
    'Electricity (SE)',
    'What is the SE electricity website, outage number, and home tariff per kWh?',
  ),
  ('Driving, Muroor and cars', 'How do I renew a driving licence in Saudi?'),
  (
    'Premium residency',
    'Premium Residency on pr.gov.sa: do I need a sponsor, and what is the unlimited duration fee?',
  ),
  ('Saudi Post', 'How do I register a national address?'),
  ('Airports', 'What do I need when departing a Saudi airport?'),
  ('GOSI, Musaned and visits', 'How does a family visit visa work?'),
];

enum _BlockKind { heading, paragraph, bullets }

class _Block {
  const _Block.heading(this.text)
      : kind = _BlockKind.heading,
        bullets = const [];
  const _Block.paragraph(this.text)
      : kind = _BlockKind.paragraph,
        bullets = const [];
  const _Block.bullets(this.bullets)
      : kind = _BlockKind.bullets,
        text = '';

  final _BlockKind kind;
  final String text;
  final List<String> bullets;

  static List<_Block> parse(String raw) {
    final blocks = <_Block>[];
    final pending = <String>[];

    void flushBullets() {
      if (pending.isEmpty) return;
      blocks.add(_Block.bullets(List<String>.from(pending)));
      pending.clear();
    }

    for (final original in raw.split('\n')) {
      final line = original.trim();
      if (line.isEmpty) {
        flushBullets();
        continue;
      }
      final bullet = RegExp(r'^(?:[•\-\*]|\d+[.)])\s+').firstMatch(line);
      if (bullet != null) {
        final item = line.substring(bullet.end).trim();
        if (item.isNotEmpty) pending.add(item);
        continue;
      }
      flushBullets();
      final heading = _headingText(line);
      if (heading != null) {
        blocks.add(_Block.heading(heading));
      } else {
        blocks.add(_Block.paragraph(line));
      }
    }
    flushBullets();
    return blocks;
  }

  static String? _headingText(String line) {
    final hashes = RegExp(r'^#{1,3}\s+(.+)$').firstMatch(line);
    if (hashes != null) return hashes.group(1)!.trim();
    final stars = RegExp(r'^\*\*(.+?)\*\*:?$').firstMatch(line);
    if (stars != null) return stars.group(1)!.trim();
    if (line.length <= 48 &&
        line.endsWith(':') &&
        !line.contains('http') &&
        !line.contains('SAR')) {
      return line.substring(0, line.length - 1).trim();
    }
    return null;
  }
}

class KsaChatScreen extends StatefulWidget {
  const KsaChatScreen({super.key});

  @override
  State<KsaChatScreen> createState() => _KsaChatScreenState();
}

class _KsaChatScreenState extends State<KsaChatScreen>
    with SingleTickerProviderStateMixin {
  final _api = const KsaApiService();
  final _speech = SpeechToText();
  final _tts = FlutterTts();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <_Turn>[];

  late final AnimationController _pulse;
  late String _sessionId;

  _Phase _phase = _Phase.off;
  bool _speechReady = false;
  bool _busy = false;
  bool _voiceOpen = false;
  bool _ignoreSpeech = false;
  String _heard = '';
  String? _voiceAnswer;
  String? _voiceError;
  String? _localeId;
  double _sound = 0;
  int _speakToken = 0;
  int _listenRetries = 0;

  @override
  void initState() {
    super.initState();
    _sessionId = 'ksa-${DateTime.now().millisecondsSinceEpoch}';
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _prepareVoice();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _input.dispose();
    _scroll.dispose();
    _tts.stop();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _prepareVoice() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final engines = await _tts.getEngines;
          if (engines is List &&
              engines.any((engine) => '$engine'.contains('com.google.android.tts'))) {
            await _tts.setEngine('com.google.android.tts');
          }
        } catch (_) {}
      }
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1);
      await _tts.setVolume(1);
      await _useNaturalVoice();
    } catch (_) {}

    final ok = await _speech.initialize(
      onError: _onSpeechError,
      onStatus: _onSpeechStatus,
    );
    _speech.errorListener = _onSpeechError;
    _speech.statusListener = _onSpeechStatus;
    if (!mounted) return;
    String? localeId;
    if (ok) {
      final locales = await _speech.locales();
      final english = locales.where(
        (locale) => locale.localeId.toLowerCase().startsWith('en'),
      );
      localeId = english.isEmpty ? null : english.first.localeId;
    }
    if (!mounted) return;
    setState(() {
      _speechReady = ok;
      _localeId = localeId;
    });
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted || _ignoreSpeech) return;
    const quiet = {'error_no_match', 'error_speech_timeout'};
    if (quiet.contains(error.errorMsg)) {
      setState(() {
        if (_phase == _Phase.listening) {
          _phase = _voiceOpen ? _Phase.idle : _Phase.off;
        }
        _voiceError = null;
      });
      return;
    }
    const retryable = {'error_network', 'error_network_timeout', 'error_busy', 'error_client'};
    if (_voiceOpen && _listenRetries < 1 && retryable.contains(error.errorMsg)) {
      _listenRetries++;
      _startListening(voice: true, retry: true);
      return;
    }
    final message = switch (error.errorMsg) {
      'error_network' || 'error_network_timeout' || 'error_server' =>
        'Voice recognition needs a connection. Tap talk again.',
      'error_insufficient_permissions' || 'error_permission' =>
        'Allow the microphone, then try voice again.',
      _ => 'Voice did not start. Tap talk again.',
    };
    setState(() {
      if (_phase == _Phase.listening) {
        _phase = _voiceOpen ? _Phase.idle : _Phase.off;
      }
      _voiceError = message;
    });
  }

  Future<void> _useNaturalVoice() async {
    final raw = await _tts.getVoices;
    if (raw is! List) return;
    const favorites = [
      'en-us-x-iog',
      'en-us-x-tpf',
      'en-us-x-sfg',
      'en-us-x-tpd',
      'en-us-x-iob',
      'en-us-x-iom',
      'samantha',
      'ava',
      'allison',
      'nicky',
    ];
    Map? best;
    var bestScore = -1;
    for (final item in raw) {
      if (item is! Map) continue;
      final locale = '${item['locale'] ?? ''}'.toLowerCase().replaceAll('_', '-');
      if (!locale.startsWith('en-us')) continue;
      final features = '${item['features'] ?? ''}'.toLowerCase();
      if (features.contains('notinstalled')) continue;
      final name = '${item['name'] ?? ''}'.toLowerCase();
      final quality = '${item['quality'] ?? ''}'.toLowerCase();
      var score = switch (quality) {
        'very high' || 'premium' => 500,
        'high' || 'enhanced' => 320,
        'normal' || 'default' => 120,
        _ => 40,
      };
      if ('${item['network_required']}' == '1') score -= 25;
      for (var i = 0; i < favorites.length; i++) {
        if (name.contains(favorites[i])) score += 220 - (i * 12);
      }
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }
    if (best == null) return;
    final voice = <String, String>{
      'name': '${best['name']}',
      'locale': '${best['locale']}',
    };
    final identifier = best['identifier'];
    if (identifier != null && '$identifier'.isNotEmpty) {
      voice['identifier'] = '$identifier';
    }
    await _tts.setVoice(voice);
  }

  void _onSpeechStatus(String status) {
    if (!mounted || _ignoreSpeech) return;
    if (status != 'done' && status != 'notListening') return;
    if (_phase != _Phase.listening) return;
    final words = _heard.trim();
    if (words.isEmpty) {
      setState(() => _phase = _voiceOpen ? _Phase.idle : _Phase.off);
      return;
    }
    _submit(words, voice: _voiceOpen);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted || _ignoreSpeech) return;
    final words = result.recognizedWords.trim();
    setState(() => _heard = words);
    if (!_voiceOpen) {
      _input.value = TextEditingValue(
        text: words,
        selection: TextSelection.collapsed(offset: words.length),
      );
    }
    if (result.finalResult && words.isNotEmpty) {
      _submit(words, voice: _voiceOpen);
    }
  }

  Future<void> _startListening({required bool voice, bool retry = false}) async {
    if (!_speechReady) {
      setState(() {
        _voiceError = 'Allow the microphone, then try voice again.';
      });
      if (!voice && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Allow the microphone to ask by voice.')),
        );
      }
      return;
    }
    _ignoreSpeech = false;
    if (!retry) _listenRetries = 0;
    if (_speech.isListening) await _speech.cancel();
    await _tts.stop();
    if (!mounted) return;
    setState(() {
      _voiceOpen = voice;
      _phase = _Phase.listening;
      _heard = '';
      _sound = 0;
      _voiceError = null;
      if (voice) _voiceAnswer = null;
      if (!voice) _input.clear();
    });
    HapticFeedback.mediumImpact();
    await _speech.listen(
      onResult: _onSpeechResult,
      onSoundLevelChange: (level) {
        if (!mounted || !_voiceOpen) return;
        final next = ((level + 2) / 12).clamp(0.0, 1.0);
        if ((next - _sound).abs() < 0.05) return;
        setState(() => _sound = next);
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        autoPunctuation: true,
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 30),
        localeId: _localeId,
        contextualPhrases: const [
          'Iqama',
          'Qiwa',
          'Absher',
          'exit re-entry',
          'final exit',
          'GOSI',
          'Muqeem',
        ],
      ),
    );
  }

  Future<void> _closeVoice() async {
    _ignoreSpeech = true;
    if (_speech.isListening) await _speech.cancel();
    await _tts.stop();
    if (!mounted) return;
    setState(() {
      _voiceOpen = false;
      _phase = _Phase.off;
      _heard = '';
      _sound = 0;
      _voiceAnswer = null;
    });
  }

  Future<void> _interruptAndListen() async {
    _speakToken++;
    await _tts.stop();
    await _startListening(voice: true);
  }

  Future<void> _onVoiceAction() async {
    if (_phase == _Phase.thinking) return;
    if (_phase == _Phase.speaking) {
      await _interruptAndListen();
      return;
    }
    if (_phase == _Phase.listening) {
      if (_heard.trim().isNotEmpty) await _speech.stop();
      return;
    }
    await _startListening(voice: true);
  }

  void _reset() {
    _closeVoice();
    setState(() {
      _turns.clear();
      _sessionId = 'ksa-${DateTime.now().millisecondsSinceEpoch}';
      _input.clear();
    });
  }

  Future<void> _submit(String text, {required bool voice}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _busy) return;
    _busy = true;
    _ignoreSpeech = true;
    if (_speech.isListening) await _speech.cancel();
    _input.clear();
    setState(() {
      _heard = '';
      _sound = 0;
      _phase = voice ? _Phase.thinking : _Phase.off;
      if (!voice) _turns.add(_Turn(role: _Role.user, text: trimmed));
      _turns.add(
        _Turn(
          role: _Role.assistant,
          text: '',
          pending: true,
        ),
      );
    });
    _scrollDown();

    try {
      final reply = await _api.send(
        message: trimmed,
        sessionId: _sessionId,
        onPartial: (partial) {
          if (!mounted) return;
          setState(() {
            final turn = _turns.last;
            turn.text = partial;
            turn.pending = false;
          });
          _scrollDown();
        },
      );
      if (!mounted) return;
      setState(() {
        final turn = _turns.last;
        turn.text = reply.text;
        turn.sources = reply.sources;
        turn.pending = false;
      });
      _scrollDown();
      if (voice && _voiceOpen) {
        final token = ++_speakToken;
        setState(() {
          _phase = _Phase.speaking;
          _voiceAnswer = reply.text;
        });
        await _speak(reply.text);
        if (!mounted || !_voiceOpen || token != _speakToken) return;
        if (_phase == _Phase.speaking) setState(() => _phase = _Phase.idle);
      }
    } on KsaApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _turns.removeLast();
        _turns.add(
          _Turn(role: _Role.assistant, text: error.message, failed: true),
        );
        if (voice) {
          _phase = _Phase.idle;
          _voiceAnswer = error.message;
        }
      });
      _scrollDown();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _turns.removeLast();
        _turns.add(
          _Turn(
            role: _Role.assistant,
            text: 'Something went wrong talking to the local model. $error',
            failed: true,
          ),
        );
        if (voice) {
          _phase = _Phase.idle;
          _voiceAnswer = 'Something went wrong talking to the local model.';
        }
      });
    } finally {
      _busy = false;
      _ignoreSpeech = false;
    }
  }

  Future<void> _onComposerMic() async {
    if (_phase == _Phase.speaking && _voiceOpen) {
      await _interruptAndListen();
      return;
    }
    await _startListening(voice: true);
  }

  Future<void> _speak(String text) async {
    final token = _speakToken;
    var spoken = text
        .replaceAll(RegExp(r'\[[^\]]*\]\([^)]*\)'), ' ')
        .replaceAll(RegExp(r'https?://\S+'), ' ')
        .replaceAll(RegExp(r'[#*_>`]'), ' ')
        .replaceAll(RegExp(r'\bSAR\b'), 'riyals')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (spoken.length > 1600) {
      final cut = spoken.lastIndexOf('.', 1600);
      spoken = cut > 400 ? spoken.substring(0, cut + 1) : spoken.substring(0, 1600);
      spoken = '$spoken The rest of the answer is on the screen.';
    }
    if (spoken.isEmpty || token != _speakToken) return;
    try {
      await _tts.stop();
      if (token != _speakToken) return;
      await _tts.speak(spoken);
    } catch (_) {}
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_voiceOpen) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: _voiceStage(),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Ask KSA'),
        actions: [
          IconButton(
            tooltip: 'Voice',
            onPressed: () => _startListening(voice: true),
            icon: const Icon(Icons.graphic_eq_rounded),
          ),
          IconButton(
            tooltip: 'New chat',
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _turns.isEmpty ? _empty() : _thread(),
              ),
              _composer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.stroke),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, I am KSA Guide',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'I will help you with these topics. Tap a cell, type a question, or use Voice.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final topic in _topics)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TopicCell(
              label: topic.$1,
              onTap: _busy ? null : () => _submit(topic.$2, voice: false),
            ),
          ),
      ],
    );
  }

  Widget _thread() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      itemCount: _turns.length,
      itemBuilder: (context, index) => _bubble(_turns[index]),
    );
  }

  Widget _bubble(_Turn turn) {
    final mine = turn.role == _Role.user;
    final bg = mine
        ? AppColors.greenDeep
        : turn.failed
            ? const Color(0xFFF8EBE7)
            : AppColors.card;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (turn.pending)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (mine)
              Text(
                turn.text,
                style: TextStyle(
                  color: mine ? Colors.white : AppColors.ink,
                  height: 1.4,
                  fontWeight: mine ? FontWeight.w700 : FontWeight.w500,
                ),
              )
            else ...[
              for (final block in _Block.parse(turn.text))
                switch (block.kind) {
                  _BlockKind.heading => Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(
                        block.text,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                    ),
                  _BlockKind.paragraph => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _RichLine(block.text),
                    ),
                  _BlockKind.bullets => Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final cell in block.bullets)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '•  ',
                                    style: TextStyle(
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.w800,
                                      height: 1.45,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Expanded(child: _RichLine(cell)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                },
            ],
            if (turn.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final source in turn.sources)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.chip,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.stroke),
                      ),
                      child: Text(
                        _prettySource(source),
                        style: const TextStyle(
                          color: AppColors.goldSoft,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (!mine && !turn.pending && !turn.failed)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Read aloud',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _speak(turn.text),
                  icon: const Icon(Icons.volume_up_rounded, color: AppColors.gold, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Speak',
                onPressed: _busy ? null : _onComposerMic,
                icon: Icon(
                  _phase == _Phase.listening && !_voiceOpen
                      ? Icons.mic_rounded
                      : Icons.mic_none_rounded,
                  color: AppColors.gold,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _busy ? null : (value) => _submit(value, voice: false),
                  decoration: const InputDecoration(
                    hintText: 'Ask about visas, iqama, Qiwa…',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Send',
                onPressed: _busy ? null : () => _submit(_input.text, voice: false),
                icon: const Icon(Icons.arrow_upward_rounded, color: AppColors.goldSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _voiceStage() {
    final listening = _phase == _Phase.listening;
    final speaking = _phase == _Phase.speaking;
    final thinking = _phase == _Phase.thinking;
    final showAnswer = _voiceAnswer != null && !listening && !thinking;
    final title = listening
        ? 'Listening'
        : thinking
            ? 'Looking that up'
            : speaking
                ? 'Answering'
                : 'Voice';

    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Close voice',
                    onPressed: _closeVoice,
                    icon: const Icon(Icons.close_rounded, color: AppColors.navy),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              if (_voiceError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    _voiceError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.red),
                  ),
                ),
              Expanded(
                child: showAnswer
                    ? _answerPane(_voiceAnswer!)
                    : _listenPane(listening: listening, thinking: thinking),
              ),
              if (showAnswer) ...[
                const SizedBox(height: 12),
                _Equalizer(
                  animation: _pulse,
                  active: speaking,
                  level: speaking ? 0.7 : 0,
                ),
                const SizedBox(height: 16),
              ],
              _voiceButton(
                listening: listening,
                speaking: speaking,
                thinking: thinking,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listenPane({required bool listening, required bool thinking}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ListenRings(
          animation: _pulse,
          active: listening || thinking,
          icon: thinking ? Icons.hourglass_top_rounded : Icons.mic_rounded,
        ),
        const SizedBox(height: 36),
        _Equalizer(
          animation: _pulse,
          active: listening,
          level: _sound,
        ),
        const SizedBox(height: 22),
        Text(
          listening
              ? 'Speak your question'
              : thinking
                  ? 'Finding the answer'
                  : 'Tap talk to ask',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _answerPane(String text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _voiceButton({
    required bool listening,
    required bool speaking,
    required bool thinking,
  }) {
    final done = listening && _heard.trim().isNotEmpty;
    if (thinking || (listening && !done)) return const SizedBox(height: 8);
    final label = speaking
        ? 'Interrupt'
        : done
            ? 'Done'
            : listening
                ? 'Listening'
                : 'Talk again';
    final filled = !listening || done;
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: listening && !done ? null : _onVoiceAction,
        style: FilledButton.styleFrom(
          backgroundColor: filled ? AppColors.greenDeep : AppColors.chip,
          disabledBackgroundColor: AppColors.chip,
          foregroundColor: filled ? AppColors.onDark : AppColors.navy,
          disabledForegroundColor: AppColors.muted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        child: Text(label),
      ),
    );
  }
}

class _ListenRings extends StatelessWidget {
  const _ListenRings({
    required this.animation,
    required this.active,
    required this.icon,
  });

  final Animation<double> animation;
  final bool active;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 3; i++) _ring(t, i),
              Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.greenDeep, AppColors.green],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: active ? 0.28 : 0.1),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(icon, color: AppColors.onDark, size: 56),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double t, int index) {
    if (!active) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.green.withValues(alpha: 0.12)),
        ),
      );
    }
    final phase = (t + index / 3) % 1;
    return Transform.scale(
      scale: 0.62 + phase * 0.62,
      child: Container(
        width: 230,
        height: 230,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.green.withValues(alpha: (1 - phase) * 0.5),
            width: 2.5,
          ),
        ),
      ),
    );
  }
}

class _Equalizer extends StatelessWidget {
  const _Equalizer({
    required this.animation,
    required this.active,
    required this.level,
  });

  final Animation<double> animation;
  final bool active;
  final double level;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final energy = active ? 0.35 + level.clamp(0.0, 1.0) * 0.85 : 0.0;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(9, (index) {
              final wave = math.sin((animation.value * math.pi * 2) + index * 0.62);
              final height = active ? 12 + ((wave + 1) * 24 * energy) : 8.0;
              return Container(
                width: 7,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: active ? 0.92 : 0.28),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

String _prettySource(String title) {
  var name = title.split('/').last;
  name = name.replaceAll(RegExp(r'\.(pdf|json|txt|md)$', caseSensitive: false), '');
  name = name.replaceAll(RegExp(r'-[0-9a-f]{8}-[0-9a-f-]{20,}$'), '');
  name = name.replaceFirst(RegExp(r'^\d+[_\s-]*'), '');
  name = name.replaceAll('_', ' ').trim();
  return name.isEmpty ? title : name;
}

class _RichLine extends StatelessWidget {
  const _RichLine(this.text);

  final String text;

  static final _tokenRe = RegExp(
    r'\[([^\]]+)\]\((https?:\/\/[^\s)]+|www\.[^\s)]+)\)'
    r'|(https?:\/\/[^\s<>\[\]()]+|www\.[^\s<>\[\]()]+)'
    r'|\*\*(.+?)\*\*',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      color: AppColors.ink,
      height: 1.45,
      fontWeight: FontWeight.w500,
      fontSize: 15,
    );
    const linkStyle = TextStyle(
      color: AppColors.green,
      height: 1.45,
      fontWeight: FontWeight.w700,
      fontSize: 15,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.green,
    );
    const boldStyle = TextStyle(
      fontWeight: FontWeight.w800,
      color: AppColors.navy,
      height: 1.45,
      fontSize: 15,
    );

    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in _tokenRe.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      final mdLabel = match.group(1);
      final mdUrl = match.group(2);
      final bareUrl = match.group(3);
      final bold = match.group(4);
      if (mdLabel != null && mdUrl != null) {
        final href = mdUrl;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => openInAppBrowser(context, url: href, title: mdLabel),
              child: Text(mdLabel, style: linkStyle),
            ),
          ),
        );
      } else if (bareUrl != null) {
        final href = bareUrl;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => openInAppBrowser(context, url: href),
              child: Text(href, style: linkStyle),
            ),
          ),
        );
      } else if (bold != null) {
        spans.add(TextSpan(text: bold, style: boldStyle));
      }
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    if (spans.isEmpty) {
      return Text(text, style: base);
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }
}

class _TopicCell extends StatelessWidget {
  const _TopicCell({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.chip,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

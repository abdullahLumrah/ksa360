import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'ksa_api_config.dart';

class KsaChatReply {
  const KsaChatReply({required this.text, required this.sources});

  final String text;
  final List<String> sources;
}

class KsaApiException implements Exception {
  KsaApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class KsaApiService {
  const KsaApiService();

  static final _helloRe = RegExp(
    r'^(hi+|hello|hey|yo|salam|salaam|marhaba|marhaban|assalamu?\s*alaikum|as-?salam(?:u)?(?:\s*alaikum)?|good (?:morning|evening|afternoon)|how are you|thanks|thank you|thx|shukran|ok(?:ay)?|أهلاً?|اهلا|هلا|مرحبا|السلام عليكم|كيف حالك|شكرا(?:ً| لك)?|تمام)[\s!.؟?]*$',
    caseSensitive: false,
  );

  static const englishGreeting =
      'Hello, I am KSA Guide. I will help you with these topics.\n'
      '\n'
      '• Iqama, Absher, visas and labour (Qiwa)\n'
      '• Ejar, Balady, water and electricity\n'
      '• Driving, Muroor and cars\n'
      '• Marketplace / Souq buys and sells\n'
      '• Jobs in Saudi Arabia\n'
      '• Clinics, hospitals and hotlines\n'
      '• Study Here — international schools\n'
      '• Daily life tips and earning ideas from our guides\n'
      '\n'
      'What do you need?';

  static const arabicGreeting =
      'أهلاً، أنا KSA Guide. أقدر أساعدك في هالمواضيع.\n'
      '\n'
      '• الإقامة وأبشر والتأشيرات وقوى\n'
      '• إيجار وبلدي والمياه والكهرباء\n'
      '• المرور والسيارات\n'
      '• السوق / بيع وشراء\n'
      '• الوظائف في السعودية\n'
      '• العيادات والمستشفيات والطوارئ\n'
      '• الدراسة هنا — المدارس العالمية\n'
      '• نصائح يومية وفرص دخل من أدلة التطبيق\n'
      '\n'
      'وش تبي؟';

  static bool isGreeting(String text) => _helloRe.hasMatch(text.trim());

  static String greetingFor(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text)
        ? arabicGreeting
        : englishGreeting;
  }

  Future<KsaChatReply> send({
    required String message,
    required String sessionId,
    void Function(String partial)? onPartial,
  }) async {
    if (KsaApiConfig.apiKey.isEmpty) {
      throw KsaApiException(
        'AnythingLLM has no API key yet. Create one in AnythingLLM under Settings, then API Keys.',
      );
    }

    if (isGreeting(message)) {
      final greeting = greetingFor(message);
      onPartial?.call(greeting);
      return KsaChatReply(text: greeting, sources: const []);
    }

    final uri = Uri.parse(
      '${KsaApiConfig.baseUrl}/api/v1/workspace/${KsaApiConfig.workspace}/stream-chat',
    );

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.postUrl(uri).timeout(
        const Duration(seconds: 8),
      );
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${KsaApiConfig.apiKey}');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      request.add(
        utf8.encode(
          jsonEncode({
            'message':
                'Answer from the embedded KSA Guide documents and app data packs '
                '(official PDFs, Marketplace, Jobs, Clinics, Study Here schools, '
                'school admission guide with steps/documents, and guide articles). '
                'Start with a direct yes/no or number in one sentence. '
                'Then use a short **bold title** and normal sentences. '
                'Use a • bullet only for a real list of options or steps. '
                'For school admission questions, use the school admission guide and '
                'school-specific steps/documents when available. '
                'For hospitals/clinics (e.g. Hamadi/Hammadi/الحمادي/HAMC), use the '
                'Clinics healthcare pack: give city, lat/lng, phone when known, and '
                'always include the full Google Maps URL as https://www.google.com/maps/search/?api=1&query=LAT,LNG '
                '(or the Maps link from the pack). Treat Hamadi/Hammadi/Al Hammadi as '
                'مستشفى الحمادي in Riyadh when that matches. '
                'Do not reply with a hello menu or turn the whole answer into bullets. '
                'If a fee is not in the documents, say to confirm on the official site.\n\n'
                '$message',
            'mode': 'chat',
            'sessionId': sessionId,
          }),
        ),
      );

      final response = await request.close().timeout(const Duration(seconds: 20));
      if (response.statusCode == 403) {
        throw KsaApiException('AnythingLLM rejected the API key.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw KsaApiException('AnythingLLM returned ${response.statusCode}.');
      }

      final assembled = StringBuffer();
      var sources = const <String>[];
      String? streamError;
      final lineBuf = StringBuffer();

      await for (final chunk in response.transform(utf8.decoder).timeout(
        const Duration(seconds: 90),
      )) {
        lineBuf.write(chunk);
        var raw = lineBuf.toString();
        final parts = raw.split('\n');
        lineBuf
          ..clear()
          ..write(parts.removeLast());
        for (final line in parts) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;
          final payload = trimmed.substring(5).trim();
          if (payload.isEmpty || payload == '[DONE]') continue;
          final event = _decode(payload);
          final type = (event['type'] ?? '').toString();
          final err = event['error'];
          if (err is String && err.trim().isNotEmpty && err != 'false') {
            streamError = err.trim();
          }
          if (type == 'textResponseChunk') {
            assembled.write((event['textResponse'] ?? '').toString());
            onPartial?.call(_stripThink(assembled.toString()));
          } else if (type == 'finalizeResponseStream') {
            sources = _sources(event['sources']);
          } else if (type == 'abort') {
            streamError ??= 'The model stopped before finishing.';
          }
        }
      }

      if (streamError != null && assembled.isEmpty) {
        throw KsaApiException(streamError);
      }
      final text = _stripThink(assembled.toString());
      if (text.isEmpty) {
        throw KsaApiException('The model returned an empty answer.');
      }
      return KsaChatReply(text: text, sources: sources);
    } on TimeoutException {
      throw KsaApiException(
        'The local model is still thinking. Keep AnythingLLM and Ollama open, then ask again.',
      );
    } on SocketException {
      throw KsaApiException(
        'Cannot reach AnythingLLM at ${KsaApiConfig.baseUrl}. Open the AnythingLLM app on this Mac.',
      );
    } on HttpException {
      throw KsaApiException(
        'Cannot reach AnythingLLM at ${KsaApiConfig.baseUrl}. Open the AnythingLLM app on this Mac.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Map<String, dynamic> _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  String _stripThink(String raw) {
    final without = raw.replaceAll(
      RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false),
      '',
    );
    return without
        .replaceAll(RegExp(r'</?think>', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^A:\s*'), '')
        .trim();
  }

  List<String> _sources(Object? raw) {
    if (raw is! List) return const [];
    final titles = <String>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final title = (item['title'] ?? item['name'] ?? '').toString().trim();
      if (title.isEmpty || titles.contains(title)) continue;
      titles.add(title);
    }
    return titles;
  }
}

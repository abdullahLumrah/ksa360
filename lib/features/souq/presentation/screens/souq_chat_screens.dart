import 'package:flutter/material.dart';

import '../../../../data/auth_session.dart';
import '../../../../theme/app_theme.dart';
import '../../data/souq_api.dart';
import '../../domain/souq_models.dart';
import '../souq_controller.dart';
import '../souq_format.dart';
import '../souq_l10n.dart';
import '../souq_sell.dart';
import '../widgets/souq_ad_card.dart';
import '../widgets/souq_widgets.dart';

class SouqChatListScreen extends StatefulWidget {
  const SouqChatListScreen({super.key, this.adId});
  final String? adId;

  @override
  State<SouqChatListScreen> createState() => _SouqChatListScreenState();
}

class _SouqChatListScreenState extends State<SouqChatListScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await SouqController.instance.ensureReady();
    if (!AuthSession.instance.isSignedIn) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    await SouqController.instance.refreshChats(adId: widget.adId);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        SouqController.instance,
        AuthSession.instance,
      ]),
      builder: (context, _) {
        if (!AuthSession.instance.isSignedIn) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(title: Text(l10n.chats)),
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  if (await ensureSouqSignedIn(context)) _load();
                },
                child: Text(l10n.signInToChat),
              ),
            ),
          );
        }
        final chats = SouqController.instance.repo.conversations
            .where((c) => widget.adId == null || c.adId == widget.adId)
            .toList();
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text(widget.adId == null ? l10n.chats : l10n.inquiries),
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : chats.isEmpty
                  ? SouqEmpty(title: l10n.noChats)
                  : ListView.separated(
                      itemCount: chats.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final c = chats[i];
                        return ListTile(
                          title: Text(c.peerName),
                          subtitle: Text(
                            c.preview.isEmpty ? c.adTitle : c.preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SouqChatThreadScreen(
                                adId: c.adId,
                                conversationId: c.id,
                              ),
                            ),
                          ).then((_) => _load()),
                        );
                      },
                    ),
        );
      },
    );
  }
}

class SouqChatThreadScreen extends StatefulWidget {
  const SouqChatThreadScreen({
    super.key,
    required this.adId,
    this.conversationId,
  });
  final String adId;
  final String? conversationId;

  @override
  State<SouqChatThreadScreen> createState() => _SouqChatThreadScreenState();
}

class _SouqChatThreadScreenState extends State<SouqChatThreadScreen> {
  final _text = TextEditingController();
  Ad? _ad;
  SouqConversation? _convo;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await SouqController.instance.ensureReady();
    if (!AuthSession.instance.isSignedIn) {
      if (!mounted) return;
      setState(() => _error = SouqL10n.of(context).signInToChat);
      return;
    }
    try {
      final ad = await SouqController.instance.repo.byId(widget.adId);
      final convo = widget.conversationId != null
          ? await SouqApi.chat(widget.conversationId!)
          : await SouqController.instance.repo.openChat(ad: ad!);
      if (!mounted) return;
      setState(() {
        _ad = ad;
        _convo = convo;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _convo == null || _sending) return;
    if (!(_convo!.canSend)) return;
    setState(() => _sending = true);
    try {
      await SouqController.instance.repo.sendMessage(_convo!.id, text.trim());
      _text.clear();
      final next = await SouqApi.chat(_convo!.id);
      if (!mounted) return;
      setState(() {
        _convo = next;
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    final ad = _ad;
    final convo = _convo;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(ad?.title ?? convo?.adTitle ?? l10n.chat)),
      body: _error != null && convo == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : Column(
              children: [
                if (ad != null)
                  Material(
                    color: AppColors.card,
                    child: ListTile(
                      leading: SizedBox(
                        width: 48,
                        height: 48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SouqCover(ad: ad),
                        ),
                      ),
                      title: Text(ad.title, maxLines: 1),
                      subtitle: Text(SouqFormat.sar(ad.price, ar: l10n.ar)),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (convo != null)
                        for (final m in convo.messages)
                          Align(
                            alignment: m.fromMe
                                ? AlignmentDirectional.centerEnd
                                : AlignmentDirectional.centerStart,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: m.fromMe ? AppColors.green : AppColors.chip,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                m.text,
                                style: TextStyle(
                                  color: m.fromMe ? Colors.white : AppColors.ink,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                if (convo != null && convo.isSeller)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      l10n.onlyOwnerReplies,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                if (convo != null && convo.canSend && !convo.isSeller)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: Text(l10n.stillAvailable),
                          onPressed: () => _send(l10n.stillAvailable),
                        ),
                        ActionChip(
                          label: Text(l10n.finalPrice),
                          onPressed: () => _send(l10n.finalPrice),
                        ),
                        ActionChip(
                          label: Text(l10n.whereSee),
                          onPressed: () => _send(l10n.whereSee),
                        ),
                      ],
                    ),
                  ),
                if (convo == null || convo.canSend)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _text,
                              enabled: !_sending,
                              decoration: const InputDecoration(hintText: 'Message'),
                              onSubmitted: _send,
                            ),
                          ),
                          IconButton(
                            onPressed: _sending ? null : () => _send(_text.text),
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.onlyOwnerReplies,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

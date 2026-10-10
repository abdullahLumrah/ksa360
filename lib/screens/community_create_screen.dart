import 'package:flutter/material.dart';

import '../data/auth_session.dart';
import '../data/community_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_filter_chip.dart';
import 'auth_sheet.dart';
import 'community_page_screen.dart';

class CommunityCreateScreen extends StatefulWidget {
  const CommunityCreateScreen({super.key});

  @override
  State<CommunityCreateScreen> createState() => _CommunityCreateScreenState();
}

class _CommunityCreateScreenState extends State<CommunityCreateScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController();
  String _topic = 'General';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final topics = CommunityRepository.instance.topics;
    if (topics.isNotEmpty) _topic = topics.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final name = _name.text.trim();
    if (name.length < 3) {
      setState(() => _error = 'Give the page a clear name (at least 3 characters).');
      return;
    }
    if (!AuthSession.instance.isSignedIn) {
      await showAuthSheet(context);
      if (!mounted || !AuthSession.instance.isSignedIn) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = await CommunityRepository.instance.create(
        name: name,
        description: _description.text.trim(),
        topic: _topic,
        city: _city.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CommunityPageScreen(communityId: page.id)),
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!mounted) return;
      if (msg.toLowerCase().contains('sign in')) {
        await showAuthSheet(context);
        if (mounted) {
          setState(() => _error = 'Sign in again, then tap Create page.');
        }
      } else {
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topics = CommunityRepository.instance.topics;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Create a page')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Text(
                  'Name it clearly — people will find it by topic and city.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Page name',
                    hintText: 'e.g. Filipino Community Riyadh',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'About',
                    hintText: 'What is this page for?',
                  ),
                ),
                const SizedBox(height: 8),
                Text('Topic', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: topics.map((topic) {
                    final on = topic == _topic;
                    return AppFilterChip(
                      label: topic,
                      selected: on,
                      onSelected: (_) => setState(() => _topic = topic),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _city,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'City (optional)',
                    hintText: 'Riyadh, Jeddah…',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? 'Creating…' : 'Create page'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

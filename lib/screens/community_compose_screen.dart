import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/auth_session.dart';
import '../data/community_repository.dart';
import '../models/community.dart';
import '../theme/app_theme.dart';
import 'auth_sheet.dart';

class CommunityComposeScreen extends StatefulWidget {
  const CommunityComposeScreen({
    super.key,
    required this.communityId,
    this.communityName = '',
  });

  final String communityId;
  final String communityName;

  @override
  State<CommunityComposeScreen> createState() => _CommunityComposeScreenState();
}

class _CommunityComposeScreenState extends State<CommunityComposeScreen> {
  final _body = TextEditingController();
  final _picker = ImagePicker();
  String? _imagePath;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final text = _body.text.trim();
    if (text.isEmpty && (_imagePath == null || _imagePath!.isEmpty)) {
      setState(() => _error = 'Write something or attach a photo.');
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
      final post = await CommunityRepository.instance.createPost(
        widget.communityId,
        body: text,
        imagePath: _imagePath,
      );
      if (!mounted) return;
      Navigator.of(context).pop(post);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.communityName.isEmpty ? 'Create post' : 'Post to ${widget.communityName}';
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? '…' : 'Post'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(
            AuthSession.instance.user?.name ?? 'You',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Anyone can post. If you are not the page owner, your post waits for their approval.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _body,
            autofocus: true,
            maxLines: 10,
            minLines: 6,
            maxLength: 5000,
            decoration: const InputDecoration(
              hintText: 'What’s on your mind?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          if (_imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.file(
                    File(_imagePath!),
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      onPressed: _busy ? null : () => setState(() => _imagePath = null),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    final file = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                      maxWidth: 1800,
                    );
                    if (file == null || !mounted) return;
                    setState(() => _imagePath = file.path);
                  },
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_imagePath == null ? 'Add a photo' : 'Change photo'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.send_rounded),
              label: Text(_busy ? 'Posting…' : 'Create post'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the compose screen and returns the created post if any.
Future<CommunityPost?> openCommunityCompose(
  BuildContext context, {
  required String communityId,
  String communityName = '',
}) {
  return Navigator.of(context).push<CommunityPost>(
    MaterialPageRoute(
      builder: (_) => CommunityComposeScreen(
        communityId: communityId,
        communityName: communityName,
      ),
    ),
  );
}

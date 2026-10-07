import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/auth_session.dart';
import '../data/content_repository.dart';
import '../screens/auth_sheet.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';

class GuideSubmitScreen extends StatefulWidget {
  const GuideSubmitScreen({super.key});

  @override
  State<GuideSubmitScreen> createState() => _GuideSubmitScreenState();
}

class _GuideSubmitScreenState extends State<GuideSubmitScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _picker = ImagePicker();
  String? _imagePath;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSignedIn());
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _ensureSignedIn() async {
    if (AuthSession.instance.isSignedIn) return;
    await showAuthSheet(context);
    if (!mounted) return;
    if (!AuthSession.instance.isSignedIn) Navigator.of(context).pop();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null || !mounted) return;
    setState(() => _imagePath = file.path);
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final description = _description.text.trim();
    if (title.isEmpty || description.isEmpty) {
      setState(() => _error = 'Add a title and a description.');
      return;
    }
    if (!AuthSession.instance.isSignedIn) {
      await _ensureSignedIn();
      if (!AuthSession.instance.isSignedIn) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ContentRepository.instance.submitPost(
        title: title,
        description: description,
        imagePath: _imagePath,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sent for review. It appears after approval.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Suggest a guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const Text(
            'Add a photo, title, and description. We review every post before it goes live.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          PressableScale(
            borderRadius: BorderRadius.circular(20),
            onTap: _busy ? null : _pickImage,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _imagePath == null
                    ? ColoredBox(
                        color: AppColors.card,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.stroke),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    color: AppColors.gold, size: 28),
                                SizedBox(height: 8),
                                Text(
                                  'Add a photo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Image.file(File(_imagePath!), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            enabled: !_busy,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'What should people know?',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            enabled: !_busy,
            minLines: 5,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Write the guide in your own words.',
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Sending…' : 'Send for review'),
          ),
        ],
      ),
    );
  }
}

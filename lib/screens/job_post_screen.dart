import 'package:flutter/material.dart';

import '../data/auth_session.dart';
import '../data/job_repository.dart';
import '../data/saudi_cities.dart';
import '../theme/app_theme.dart';
import 'auth_sheet.dart';

class JobPostScreen extends StatefulWidget {
  const JobPostScreen({super.key});

  @override
  State<JobPostScreen> createState() => _JobPostScreenState();
}

class _JobPostScreenState extends State<JobPostScreen> {
  final _title = TextEditingController();
  final _company = TextEditingController();
  final _description = TextEditingController();
  final _salary = TextEditingController();
  final _applyUrl = TextEditingController();
  final _email = TextEditingController();
  String _category = '';
  String _city = SaudiCities.riyadh.name;
  String _employment = 'Full Time';
  String _workMode = 'On-site';
  bool _busy = false;
  String? _error;

  List<String> get _categories {
    final extra = JobRepository.instance.postCategories;
    if (extra.isNotEmpty) return extra;
    return const [
      'Administration',
      'Engineering',
      'Finance & Accounting',
      'IT & Software',
      'Human Resources',
      'Sales',
      'Other',
    ];
  }

  @override
  void initState() {
    super.initState();
    _category = _categories.first;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSignedIn());
  }

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    _description.dispose();
    _salary.dispose();
    _applyUrl.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _ensureSignedIn() async {
    if (AuthSession.instance.isSignedIn) return;
    await showAuthSheet(context);
    if (!mounted) return;
    if (!AuthSession.instance.isSignedIn) Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    if (!AuthSession.instance.isSignedIn) {
      await _ensureSignedIn();
      if (!AuthSession.instance.isSignedIn) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await JobRepository.instance.submit(
        title: _title.text.trim(),
        companyName: _company.text.trim(),
        category: _category,
        city: _city,
        description: _description.text.trim(),
        employmentType: _employment,
        workMode: _workMode,
        salaryDisplay: _salary.text.trim(),
        applyUrl: _applyUrl.text.trim(),
        contactEmail: _email.text.trim(),
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
      appBar: AppBar(title: const Text('Post a job')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Text(
            'Employer posts are reviewed before they go live. Only roles in Saudi Arabia are accepted.',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _Field(controller: _title, label: 'Job title'),
          _Field(controller: _company, label: 'Company'),
          _Dropdown(
            label: 'Category',
            value: _category,
            items: _categories,
            onChanged: (value) => setState(() => _category = value),
          ),
          _Dropdown(
            label: 'City',
            value: _city,
            items: [
              'Saudi Arabia',
              ...SaudiCities.all.map((city) => city.name),
            ],
            onChanged: (value) => setState(() => _city = value),
          ),
          _Dropdown(
            label: 'Employment type',
            value: _employment,
            items: const ['Full Time', 'Part Time', 'Contract', 'Intern'],
            onChanged: (value) => setState(() => _employment = value),
          ),
          _Dropdown(
            label: 'Work mode',
            value: _workMode,
            items: const ['On-site', 'Hybrid', 'Remote', 'Not specified'],
            onChanged: (value) => setState(() => _workMode = value),
          ),
          _Field(
            controller: _salary,
            label: 'Salary (optional, as you want it shown)',
          ),
          _Field(
            controller: _applyUrl,
            label: 'Apply link',
            keyboard: TextInputType.url,
          ),
          _Field(
            controller: _email,
            label: 'Contact email if there is no apply link',
            keyboard: TextInputType.emailAddress,
          ),
          _Field(
            controller: _description,
            label: 'Description',
            maxLines: 8,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _busy ? 'Sending…' : 'Submit for review',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboard,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.stroke),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.stroke),
          ),
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = items.contains(value) ? items : [value, ...items];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.stroke),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.stroke),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: options
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ),
    );
  }
}

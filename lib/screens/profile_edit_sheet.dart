import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/auth_session.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import 'profile_complete_sheet.dart';

Future<void> showProfileEditSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x661C1915),
    builder: (context) => const _ManageProfileSheet(),
  );
}

class _ManageProfileSheet extends StatefulWidget {
  const _ManageProfileSheet();

  @override
  State<_ManageProfileSheet> createState() => _ManageProfileSheetState();
}

class _ManageProfileSheetState extends State<_ManageProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  DateTime? _dob;
  String _gender = '';
  var _busy = false;
  String? _error;

  AppUser? get _user => AuthSession.instance.user;

  @override
  void initState() {
    super.initState();
    final user = _user;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(text: normalizeSaudiMobile(user?.phone ?? ''));
    _gender = user?.gender ?? '';
    final raw = user?.dateOfBirth ?? '';
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      _dob = DateTime.tryParse(raw);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 24, 1, 1),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 13, now.month, now.day),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_name.text.trim().length < 2) {
        throw Exception('Enter your name');
      }
      if (!isSaudiMobile(_phone.text)) {
        throw Exception('Enter a valid Saudi mobile number');
      }
      if (_dob == null) throw Exception('Add your date of birth');
      if (_gender.isEmpty) throw Exception('Choose a gender');
      await AuthSession.instance.updateProfile(
        name: _name.text.trim(),
        phone: '+966${normalizeSaudiMobile(_phone.text)}',
        dateOfBirth: DateFormat('yyyy-MM-dd').format(_dob!),
        gender: _gender,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'Your account will be deactivated now. You can sign in again within 15 days to restore it. After 15 days it is permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthSession.instance.deleteAccount();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final email = _user?.email ?? '';
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 18 + inset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.stroke,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Manage profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Name, mobile, birthday, and gender stay with your account. Email cannot be changed.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    filled: true,
                    fillColor: AppColors.bg,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Mobile number',
                    prefixText: '+966  ',
                    hintText: '5X XXX XXXX',
                    filled: true,
                    fillColor: AppColors.bg,
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _pickDob,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.stroke),
                      ),
                      child: Text(
                        _dob == null
                            ? 'Date of birth'
                            : DateFormat.yMMMMd().format(_dob!),
                        style: TextStyle(
                          color: _dob == null ? AppColors.muted : AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final item in const [
                      ('male', 'Male'),
                      ('female', 'Female'),
                      ('other', 'Other'),
                    ]) ...[
                      if (item.$1 != 'male') const SizedBox(width: 8),
                      Expanded(
                        child: Material(
                          color: _gender == item.$1
                              ? const Color(0xFFE4F0E8)
                              : AppColors.bg,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _gender = item.$1);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _gender == item.$1
                                      ? AppColors.green.withValues(alpha: 0.35)
                                      : AppColors.stroke,
                                ),
                              ),
                              child: Text(
                                item.$2,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _gender == item.$1
                                      ? AppColors.greenDeep
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: AppColors.bg,
                  ),
                  child: Text(
                    email,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.red, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : _delete,
                  child: const Text(
                    'Delete account',
                    style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/auth_session.dart';
import '../theme/app_theme.dart';

String normalizeSaudiMobile(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('966')) digits = digits.substring(3);
  if (digits.startsWith('0')) digits = digits.substring(1);
  return digits;
}

bool isSaudiMobile(String raw) =>
    RegExp(r'^5\d{8}$').hasMatch(normalizeSaudiMobile(raw));

Future<void> playConfettiBurst(BuildContext context) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _ConfettiBurstLayer(
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
  await Future<void>.delayed(const Duration(milliseconds: 1700));
}

Future<void> showProfileCompleteSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x661C1915),
    builder: (context) => const _ProfileCompleteSheet(),
  );
}

class _ProfileCompleteSheet extends StatefulWidget {
  const _ProfileCompleteSheet();

  @override
  State<_ProfileCompleteSheet> createState() => _ProfileCompleteSheetState();
}

class _ProfileCompleteSheetState extends State<_ProfileCompleteSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  DateTime? _dob;
  String _gender = '';
  var _busy = false;
  var _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = AuthSession.instance.user;
    _name = TextEditingController(text: user?.name ?? '');
    _phone = TextEditingController(
      text: normalizeSaudiMobile(user?.phone ?? ''),
    );
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

  int get _doneCount {
    var n = 0;
    if (_name.text.trim().length >= 2) n += 1;
    if (isSaudiMobile(_phone.text)) n += 1;
    if (_dob != null) n += 1;
    if (_gender.isNotEmpty) n += 1;
    return n;
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
      if (_name.text.trim().length < 2) throw Exception('Enter your name');
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
      if (!mounted) return;
      setState(() => _done = true);
      HapticFeedback.mediumImpact();
      await playConfettiBurst(context);
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
                  'Complete your profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'A few details from you — mobile, birthday, and gender. We do not take these from Google.',
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: _done ? 1 : _doneCount / 4,
                    minHeight: 8,
                    backgroundColor: AppColors.bg,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _done ? 'Profile complete' : '$_doneCount of 4 done',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
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
                  onChanged: (_) => setState(() {}),
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
                    onPressed: _busy || _done ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
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

class _ConfettiBurstLayer extends StatefulWidget {
  const _ConfettiBurstLayer({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_ConfettiBurstLayer> createState() => _ConfettiBurstLayerState();
}

class _ConfettiBurstLayerState extends State<_ConfettiBurstLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Shard> _shards;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _shards = List.generate(140, (_) => _Shard.random(rng));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          size: MediaQuery.sizeOf(context),
          painter: _BurstPainter(_shards, _ctrl.value),
        ),
      ),
    );
  }
}

class _Shard {
  _Shard({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.wobble,
    required this.color,
    required this.width,
    required this.height,
    required this.kind,
  });

  final double angle;
  final double speed;
  final double spin;
  final double wobble;
  final Color color;
  final double width;
  final double height;
  final int kind;

  factory _Shard.random(Random rng) {
    const colors = [
      Color(0xFFE8B84A),
      Color(0xFF1E7A4C),
      Color(0xFFC45C4A),
      Color(0xFF4C8DFF),
      Color(0xFFFF6B8A),
      Color(0xFFF4F1E8),
      Color(0xFF2BB673),
      Color(0xFFFFC857),
    ];
    final upward = rng.nextDouble() < 0.78;
    return _Shard(
      angle: upward
          ? -pi * 0.12 - rng.nextDouble() * pi * 0.76
          : rng.nextDouble() * pi * 2,
      speed: 380 + rng.nextDouble() * 640,
      spin: (rng.nextDouble() - 0.5) * 28,
      wobble: rng.nextDouble() * 22,
      color: colors[rng.nextInt(colors.length)],
      width: 4 + rng.nextDouble() * 8,
      height: rng.nextDouble() < 0.35
          ? 14 + rng.nextDouble() * 18
          : 7 + rng.nextDouble() * 11,
      kind: rng.nextInt(3),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.shards, this.t);

  final List<_Shard> shards;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.58);
    final explode = Curves.easeOutCubic.transform((t / 0.34).clamp(0.0, 1.0));
    final fade = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
    for (final shard in shards) {
      final x = origin.dx +
          cos(shard.angle) * shard.speed * explode +
          sin(t * 12 + shard.spin) * shard.wobble * t;
      final y = origin.dy +
          sin(shard.angle) * shard.speed * explode +
          920 * t * t;
      final paint = Paint()..color = shard.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(shard.spin * t);
      switch (shard.kind) {
        case 0:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: shard.width,
                height: shard.height,
              ),
              const Radius.circular(1.4),
            ),
            paint,
          );
        case 1:
          canvas.drawCircle(Offset.zero, shard.width * 0.45, paint);
        default:
          final path = Path()
            ..moveTo(-shard.width / 2, -shard.height / 2)
            ..quadraticBezierTo(0, 0, shard.width / 2, shard.height / 2)
            ..quadraticBezierTo(0, shard.height / 6, -shard.width / 2, -shard.height / 2);
          canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) => oldDelegate.t != t;
}

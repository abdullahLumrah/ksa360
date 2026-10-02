import 'package:flutter/material.dart';

class SouqMotion {
  static const entry = Duration(milliseconds: 400);
  static const stagger = Duration(milliseconds: 60);
  static const squish = Duration(milliseconds: 120);
  static const favorite = Duration(milliseconds: 420);
  static const shake = Duration(milliseconds: 300);
  static const morph = Duration(milliseconds: 520);
  static const sharedAxis = Duration(milliseconds: 340);
  static const count = Duration(milliseconds: 480);
  static const progress = Duration(milliseconds: 380);

  static const entryCurve = Curves.easeOutCubic;
  static const springBack = Curves.easeOutBack;
  static const shared = Curves.easeInOutCubic;

  static bool reduce(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration d(BuildContext context, Duration raw) =>
      reduce(context) ? const Duration(milliseconds: 160) : raw;

  static Widget fadeOnly({
    required BuildContext context,
    required Widget child,
    Duration delay = Duration.zero,
  }) {
    if (reduce(context)) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 180),
        builder: (context, v, c) => Opacity(opacity: v, child: c),
        child: child,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: entry + delay,
      curve: entryCurve,
      builder: (context, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - v)),
          child: c,
        ),
      ),
      child: child,
    );
  }
}

class Shake extends StatefulWidget {
  const Shake({super.key, required this.child, required this.trigger});
  final Widget child;
  final int trigger;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: SouqMotion.shake);
  }

  @override
  void didUpdateWidget(covariant Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger && widget.trigger > 0) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final x = (t == 0 || t == 1)
            ? 0.0
            : 8 * (1 - t) * (t < 0.33 || (t > 0.5 && t < 0.66) ? 1 : -1);
        return Transform.translate(offset: Offset(x, 0), child: child);
      },
      child: widget.child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

Future<T?> openCard<T extends Object?>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(SoftPageRoute<T>(page: page));
}

class SoftPageRoute<T> extends PageRouteBuilder<T> {
  SoftPageRoute({required Widget page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.045),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              ),
            );
          },
        );
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.ripple = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final BorderRadius borderRadius;
  final bool ripple;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 260),
    );
    _scale = Tween<double>(begin: 1, end: widget.scale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _highlight(bool down) {
    if (widget.onTap == null) return;
    if (down) {
      HapticFeedback.selectionClick();
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _fire() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scaled = ScaleTransition(scale: _scale, child: widget.child);
    if (widget.onTap == null) return scaled;
    return ScaleTransition(
      scale: _scale,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: _fire,
                  onHighlightChanged: _highlight,
                  overlayColor: widget.ripple
                      ? WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.pressed)) {
                            return AppColors.gold.withValues(alpha: 0.22);
                          }
                          if (states.contains(WidgetState.hovered) ||
                              states.contains(WidgetState.focused)) {
                            return AppColors.gold.withValues(alpha: 0.1);
                          }
                          return Colors.transparent;
                        })
                      : const WidgetStatePropertyAll(Colors.transparent),
                  splashFactory: InkSparkle.splashFactory,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 480 + delay.inMilliseconds.clamp(0, 280)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class StaggerIn extends StatelessWidget {
  const StaggerIn({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: Duration(milliseconds: 45 * index.clamp(0, 12)),
      offset: 14,
      child: child,
    );
  }
}

class GlowPulse extends StatefulWidget {
  const GlowPulse({
    super.key,
    required this.child,
    this.color = const Color(0xFFD4B483),
  });

  final Widget child;
  final Color color;

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = 0.18 + (_controller.value * 0.28);
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: t),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

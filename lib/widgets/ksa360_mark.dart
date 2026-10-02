import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'motion.dart';

const ksa360SplashAsset = 'assets/brand/ksa360_splash.json';

/// The KSA 360 emblem at rest. Tapping plays the splash animation once.
class Ksa360Mark extends StatefulWidget {
  const Ksa360Mark({super.key, this.size = 40});

  final double size;

  @override
  State<Ksa360Mark> createState() => _Ksa360MarkState();
}

class _Ksa360MarkState extends State<Ksa360Mark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 1);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLoaded(LottieComposition composition) {
    _controller.duration = composition.duration;
    if (!_controller.isAnimating) _controller.value = 1;
  }

  void _play() {
    if (_controller.duration == null) return;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: _play,
      child: SizedBox.square(
        dimension: widget.size,
        child: Lottie.asset(
          ksa360SplashAsset,
          controller: _controller,
          onLoaded: _onLoaded,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

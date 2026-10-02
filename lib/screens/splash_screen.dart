import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lottie/lottie.dart';

import '../data/auth_session.dart';
import '../data/activity_repository.dart';
import '../data/activity_store.dart';
import '../data/reels_repository.dart';
import '../data/reel_watch_store.dart';
import '../data/content_repository.dart';
import '../data/life_settings.dart';
import '../data/restaurant_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/ksa360_mark.dart';
import 'home_shell.dart';

// Frame timings from tools/brand/make_ksa360.py (124 frames at 60 fps).
const _frames = 124.0;
const _orbitStart = 14 / _frames;
const _orbitEnd = 72 / _frames;
const _orbitCurve = Cubic(0.6, 0, 0.3, 1);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final Ticker _clock;
  final _introDone = Completer<void>();
  Duration _introLength = const Duration(milliseconds: 2070);
  Duration _lastTick = Duration.zero;
  bool _loaded = false;
  bool _firstFrame = false;
  bool _bootDone = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this);
    _clock = createTicker(_advance);
    WidgetsBinding.instance.waitUntilFirstFrameRasterized.then((_) {
      if (!mounted) return;
      _firstFrame = true;
      _maybeStart();
      _boot();
    });
  }

  void _onComposition(LottieComposition composition) {
    _introLength = composition.duration;
    _loaded = true;
    _maybeStart();
  }

  void _maybeStart() {
    if (!_loaded || !_firstFrame || _clock.isActive || _intro.value > 0) return;
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted && !_clock.isActive) _clock.start();
    });
  }

  // Frame-driven so a busy startup slows the intro instead of skipping it.
  void _advance(Duration elapsed) {
    var step = elapsed - _lastTick;
    _lastTick = elapsed;
    if (step > const Duration(milliseconds: 34)) {
      step = const Duration(milliseconds: 34);
    }
    final next =
        _intro.value + step.inMicroseconds / _introLength.inMicroseconds;
    _intro.value = next.clamp(0.0, 1.0);
    if (next >= 1) {
      _clock.stop();
      if (!_introDone.isCompleted) _introDone.complete();
      setState(() {});
    }
  }

  Future<void> _boot() async {
    try {
      await AuthSession.instance.load();
      await Future.wait([
        ContentRepository.instance.load(),
        LifeSettings.instance.load(),
        RestaurantRepository.instance.load(),
        ActivityRepository.instance.load(),
        ReelsRepository.instance.load(),
        ActivityStore.instance.load(),
        ReelWatchStore.instance.load(),
      ]);
      if (mounted) setState(() => _bootDone = true);
      await _introDone.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      );
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeShell(),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.03, end: 1).animate(curved),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load guides. Please restart the app.');
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _intro.dispose();
    super.dispose();
  }

  double _between(double start, double end,
      [Curve curve = Curves.easeOutCubic]) {
    final t = ((_intro.value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final emblem =
        (MediaQuery.sizeOf(context).width * 0.62).clamp(200.0, 300.0);
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.22),
              radius: 1.05,
              colors: [
                Color(0xFFFBF8F2),
                AppColors.bg,
                Color(0xFFEAE2D4),
              ],
              stops: [0, 0.55, 1],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _intro,
              builder: (context, _) {
                return Column(
                  children: [
                    const Spacer(flex: 5),
                    SizedBox.square(
                      dimension: emblem,
                      child: Lottie.asset(
                        ksa360SplashAsset,
                        controller: _intro,
                        fit: BoxFit.contain,
                        onLoaded: _onComposition,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _wordmark(),
                    const SizedBox(height: 12),
                    _tagline(),
                    const Spacer(flex: 6),
                    _footer(),
                    const SizedBox(height: 28),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _wordmark() {
    final appear = _between(_orbitStart - 0.04, _orbitStart + 0.16);
    final orbit = _between(_orbitStart, _orbitEnd, _orbitCurve);
    final degrees = (orbit * 360).round();
    final landed = _between(_orbitEnd, _orbitEnd + 0.14, Curves.easeOutBack);
    final pop = 1 + (0.08 * (1 - landed)) * (orbit >= 1 ? 1 : 0);
    final tracking = 10 - (11 * appear);
    final degreeFade = _between(_orbitEnd, _orbitEnd + 0.12);

    return Opacity(
      opacity: appear,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - appear)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'KSA',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 44,
                fontWeight: FontWeight.w800,
                letterSpacing: tracking,
                height: 1,
              ),
            ),
            const SizedBox(width: 12),
            Transform.scale(
              scale: pop,
              child: Text(
                '$degrees'.padLeft(3, '0'),
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  letterSpacing: tracking.clamp(-1.0, 4.0),
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1 - degreeFade,
                child: Opacity(
                  opacity: 1 - degreeFade,
                  child: const Text(
                    '°',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagline() {
    final show = _between(0.66, 0.96);
    return Opacity(
      opacity: show,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - show)),
        child: const Column(
          children: [
            Text(
              'SAUDI ARABIA · ALL AROUND YOU',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 3.2,
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Visas, iqama, places and daily life, in one place.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.muted, fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.goldSoft),
        ),
      );
    }
    final waiting = _introDone.isCompleted && !_bootDone;
    return AnimatedOpacity(
      opacity: waiting ? 1 : 0,
      duration: const Duration(milliseconds: 240),
      child: const SizedBox(
        width: 120,
        child: LinearProgressIndicator(
          minHeight: 2,
          color: AppColors.gold,
          backgroundColor: AppColors.line,
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../data/app_analytics.dart';
import '../data/app_tabs.dart';
import '../data/healthcare_repository.dart';
import '../data/life_settings.dart';
import '../data/restaurant_repository.dart';
import '../features/souq/presentation/screens/souq_home_screen.dart';
import '../features/souq/presentation/souq_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'eat_screen.dart';
import 'jobs_screen.dart';
import 'ksa_chat_screen.dart';
import 'play_screen.dart';
import 'profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    AppTabs.index.value = 0;
    AppTabs.index.addListener(_syncTab);
    SouqController.instance.ensureReady();
    _refreshPlacesFromGps();
    AppAnalytics.instance.section('home');
  }

  Future<void> _refreshPlacesFromGps() async {
    final settings = LifeSettings.instance;
    if (settings.useGps) {
      await settings.refreshGps(request: true);
    }
    if (!mounted) return;
    final lat = settings.prayerLat;
    final lng = settings.prayerLng;
    HealthcareRepository.instance.refreshAround(lat, lng);
    RestaurantRepository.instance.refreshAround(lat, lng);
  }

  void _syncTab() {
    final next = AppTabs.index.value;
    if (next != _index && mounted) {
      setState(() => _index = next);
      const names = ['home', 'guides', 'souq', 'jobs', 'eat', 'play', 'profile'];
      AppAnalytics.instance.section(names[next.clamp(0, names.length - 1)]);
    }
  }

  @override
  void dispose() {
    AppTabs.index.removeListener(_syncTab);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [
              HomeScreen(),
              ExploreScreen(),
              SouqHomeScreen(),
              JobsScreen(),
              EatScreen(),
              PlayScreen(),
              ProfileScreen(),
            ],
          ),
          if (_index != AppTabs.souq)
            Positioned(
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 84,
              child: const _AskKsaButton(),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: _LiquidTabDock(
          index: _index,
          onChanged: (index) {
            AppTabs.go(index);
            setState(() => _index = index);
          },
        ),
      ),
    );
  }
}

class _AskKsaButton extends StatelessWidget {
  const _AskKsaButton();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ask KSA',
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            openCard(context, const KsaChatScreen());
          },
          child: Ink(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF145C3E), Color(0xFF0B3D2A)],
              ),
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.onDark,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.icon, this.label);
  final IconData icon;
  final String label;
}

const _tabs = [
  _TabSpec(Icons.home_rounded, 'Home'),
  _TabSpec(Icons.grid_view_rounded, 'Categories'),
  _TabSpec(Icons.storefront_rounded, 'Souq'),
  _TabSpec(Icons.work_outline_rounded, 'Jobs'),
  _TabSpec(Icons.restaurant_rounded, 'Eat'),
  _TabSpec(Icons.local_activity_rounded, 'Play'),
  _TabSpec(Icons.person_rounded, 'Profile'),
];

class _LiquidTabDock extends StatefulWidget {
  const _LiquidTabDock({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  @override
  State<_LiquidTabDock> createState() => _LiquidTabDockState();
}

class _LiquidTabDockState extends State<_LiquidTabDock>
    with TickerProviderStateMixin {
  int get _count => _tabs.length;

  late final AnimationController _pos;
  late final AnimationController _stretch;

  bool _dragging = false;
  int _hapticAt = 0;
  double _barWidth = 1;

  @override
  void initState() {
    super.initState();
    _pos = AnimationController.unbounded(vsync: this)
      ..value = widget.index.toDouble()
      ..addListener(() => setState(() {}));
    _stretch = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() {}));
    _hapticAt = widget.index;
  }

  @override
  void didUpdateWidget(covariant _LiquidTabDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index && !_dragging) {
      _springTo(widget.index.toDouble());
    }
  }

  @override
  void dispose() {
    _pos.dispose();
    _stretch.dispose();
    super.dispose();
  }

  double get _tabW => _barWidth / _count;

  double _rubber(double x) {
    if (x < 0) return x * 0.22;
    if (x > _count - 1) return (_count - 1) + (x - (_count - 1)) * 0.22;
    return x;
  }

  void _springTo(double target, {double velocity = 0}) {
    final sprung = SpringSimulation(
      const SpringDescription(mass: 0.78, stiffness: 210, damping: 20),
      _pos.value,
      target.clamp(0, _count - 1.0),
      velocity,
    );
    _pos.animateWith(sprung);
    _stretch.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 0.7, stiffness: 260, damping: 22),
        _stretch.value,
        0,
        0,
      ),
    );
  }

  void _commit(int index, {double velocity = 0}) {
    final next = index.clamp(0, _count - 1);
    if (next != widget.index) {
      HapticFeedback.lightImpact();
      widget.onChanged(next);
    }
    _hapticAt = next;
    _springTo(next.toDouble(), velocity: velocity);
  }

  void _tickHaptic(double pos) {
    final rounded = pos.round().clamp(0, _count - 1);
    if (rounded != _hapticAt) {
      _hapticAt = rounded;
      HapticFeedback.selectionClick();
    }
  }

  void _onDragStart(DragStartDetails _) {
    _dragging = true;
    _pos.stop();
    _stretch.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final next = _rubber(_pos.value + details.delta.dx / _tabW);
    _pos.value = next;
    final pull = (details.delta.dx / _tabW * 3.2).clamp(-0.72, 0.72);
    _stretch.value = (_stretch.value * 0.55) + (pull * 0.45);
    _tickHaptic(next);
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    final vx = details.velocity.pixelsPerSecond.dx / _tabW;
    final projected = (_pos.value + vx * 0.07).round().clamp(0, _count - 1);
    _commit(projected, velocity: vx * 0.35);
  }

  void _onTapUp(TapUpDetails details) {
    if (_dragging) return;
    final index = (details.localPosition.dx / _tabW).floor().clamp(0, _count - 1);
    _commit(index);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _dragging ? 1.025 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xF7FFFCF7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.stroke),
              boxShadow: AppShadows.card,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                _barWidth = constraints.maxWidth;
                final tabW = _tabW;
                final stretch = _stretch.value;
                final pillW = (tabW - 4) * (1 + stretch.abs() * 0.42);
                final center = (_pos.value + 0.5) * tabW;
                final left = (center - pillW / 2).clamp(2.0, _barWidth - pillW - 2);

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: _onTapUp,
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  onHorizontalDragCancel: () {
                    _dragging = false;
                    _commit(_pos.value.round());
                  },
                  child: SizedBox(
                    height: 62,
                    child: Stack(
                      children: [
                        Positioned(
                          left: left,
                          top: 4,
                          bottom: 4,
                          width: pillW,
                          child: Transform.scale(
                            scaleY: 1 - stretch.abs() * 0.06,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFFE4F0E8),
                                    const Color(0xFFF3EBDD),
                                  ],
                                ),
                                border: Border.all(
                                  color: AppColors.goldSoft.withValues(alpha: 0.35),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.10 + stretch.abs() * 0.08,
                                    ),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < _count; i++)
                              _DockItem(
                                spec: _tabs[i],
                                amount: (1 - (_pos.value - i).abs()).clamp(0.0, 1.0),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({required this.spec, required this.amount});

  final _TabSpec spec;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOutCubic.transform(amount);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 1 + (t * 0.14),
            child: Icon(
              spec.icon,
              color: Color.lerp(AppColors.muted, AppColors.goldSoft, t),
              size: 20,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            spec.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color.lerp(AppColors.muted, AppColors.goldSoft, t),
              fontSize: 8,
              fontWeight: t > 0.55 ? FontWeight.w800 : FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

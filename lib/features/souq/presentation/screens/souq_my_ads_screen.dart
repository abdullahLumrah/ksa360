import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/auth_session.dart';
import '../../../../screens/auth_sheet.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/motion.dart';
import '../../domain/souq_models.dart';
import '../souq_controller.dart';
import '../souq_format.dart';
import '../souq_l10n.dart';
import '../widgets/souq_ad_card.dart';
import 'souq_post_wizard_screen.dart';

class SouqMyAdsScreen extends StatefulWidget {
  const SouqMyAdsScreen({super.key});

  @override
  State<SouqMyAdsScreen> createState() => _SouqMyAdsScreenState();
}

class _SouqMyAdsScreenState extends State<SouqMyAdsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    SouqController.instance.ensureReady().then((_) {
      return SouqController.instance.refreshMine();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SouqController.instance.refreshMine();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        SouqController.instance,
        AuthSession.instance,
      ]),
      builder: (context, _) {
        if (!AuthSession.instance.isSignedIn) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(title: Text(l10n.myAds)),
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  await showAuthSheet(context);
                  if (AuthSession.instance.isSignedIn) {
                    await SouqController.instance.refreshMine();
                  }
                },
                child: Text(l10n.signInToSell),
              ),
            ),
          );
        }
        final ads = SouqController.instance.repo.myAds;
        final weekViews = ads.fold<int>(0, (p, a) => p + a.views);
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text(l10n.myAds),
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabs: [
                Tab(text: l10n.awaitingApproval),
                Tab(text: l10n.pending),
                Tab(text: l10n.approved),
                Tab(text: l10n.declined),
              ],
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: ListTile(
                    title: Text('$weekViews'),
                    subtitle: Text(l10n.myViews),
                    leading: const Icon(Icons.visibility_outlined),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _List(status: AdStatus.awaitingApproval, ads: ads, l10n: l10n),
                    _List(status: AdStatus.pending, ads: ads, l10n: l10n),
                    _List(status: AdStatus.approved, ads: ads, l10n: l10n),
                    _List(status: AdStatus.declined, ads: ads, l10n: l10n),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.status, required this.ads, required this.l10n});
  final AdStatus status;
  final List<Ad> ads;
  final SouqL10n l10n;

  @override
  Widget build(BuildContext context) {
    final items = ads.where((a) => a.status == status).toList();
    if (items.isEmpty) {
      return Center(child: Text('No ${status.name} ads'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final ad = items[i];
        return Dismissible(
          key: ValueKey(ad.id),
          background: const ColoredBox(color: Color(0x33B33A2B)),
          confirmDismiss: (_) async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.delete),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            );
            return ok ?? false;
          },
          onDismissed: (_) => SouqController.instance.repo.delete(ad.id),
          child: ListTile(
            tileColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.stroke),
            ),
            leading: SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SouqCover(ad: ad),
              ),
            ),
            title: Text(ad.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${SouqFormat.sar(ad.price, ar: l10n.ar)} · ${ad.views} views',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) => _act(context, ad, v),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                PopupMenuItem(value: 'sold', child: Text(l10n.markSold)),
                PopupMenuItem(
                  value: ad.status == AdStatus.paused ? 'resume' : 'pause',
                  child: Text(
                    ad.status == AdStatus.paused ? l10n.resume : l10n.pause,
                  ),
                ),
                if (ad.status == AdStatus.expired)
                  PopupMenuItem(value: 'renew', child: Text(l10n.renew)),
                PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _act(BuildContext context, Ad ad, String v) async {
    final repo = SouqController.instance.repo;
    switch (v) {
      case 'edit':
        openCard(context, SouqPostWizardScreen(existing: ad));
      case 'sold':
        HapticFeedback.mediumImpact();
        await repo.markStatus(ad.id, AdStatus.sold);
        await SouqController.instance.refreshMine();
      case 'pause':
        await repo.markStatus(ad.id, AdStatus.paused);
        await SouqController.instance.refreshMine();
      case 'resume':
        await repo.markStatus(ad.id, AdStatus.active);
        await SouqController.instance.refreshMine();
      case 'renew':
        await repo.update(
          ad.copyWith(
            status: AdStatus.active,
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          ),
        );
        await SouqController.instance.refreshMine();
      case 'delete':
        await repo.delete(ad.id);
        await SouqController.instance.refreshMine();
    }
  }
}

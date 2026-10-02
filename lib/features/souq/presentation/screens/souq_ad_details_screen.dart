import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_theme.dart';
import '../../../../widgets/motion.dart';
import '../../domain/souq_categories.dart';
import '../../domain/souq_models.dart';
import '../../../../data/app_analytics.dart';
import '../../../../data/auth_session.dart';
import '../souq_controller.dart';
import '../souq_format.dart';
import '../souq_l10n.dart';
import '../souq_sell.dart';
import '../widgets/souq_ad_card.dart';
import '../widgets/souq_widgets.dart';
import 'souq_chat_screens.dart';

class SouqAdDetailsScreen extends StatefulWidget {
  const SouqAdDetailsScreen({
    super.key,
    required this.adId,
    this.heroTag,
  });

  final String adId;
  final String? heroTag;

  @override
  State<SouqAdDetailsScreen> createState() => _SouqAdDetailsScreenState();
}

class _SouqAdDetailsScreenState extends State<SouqAdDetailsScreen> {
  Ad? _ad;
  List<Ad> _similar = [];
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await SouqController.instance.ensureReady();
    final repo = SouqController.instance.repo;
    final ad = await repo.byId(widget.adId);
    if (ad == null) return;
    AppAnalytics.instance.open(
      section: 'souq',
      targetId: ad.id,
      title: ad.title,
      category: ad.categoryId,
    );
    SouqController.instance.refresh();
    final similar = await repo.similarTo(ad);
    if (!mounted) return;
    setState(() {
      _ad = ad;
      _similar = similar;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final l10n = SouqL10n.of(context);
    if (ad == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final fav = SouqController.instance.isFavorite(ad.id);
    final cat = SouqCatalog.byId(ad.categoryId);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 320,
                backgroundColor: cat.gradient.first,
                leading: _RoundIcon(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                actions: [
                  _RoundIcon(
                    icon: Icons.share_rounded,
                    onTap: () => Share.share('${ad.title} · ${ad.city}'),
                  ),
                  _RoundIcon(
                    icon: fav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: fav ? const Color(0xFFEF4444) : null,
                    onTap: () async {
                      await toggleSouqFavorite(context, ad.id);
                      if (mounted) setState(() {});
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: GestureDetector(
                    onTap: () => _openGallery(ad),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: widget.heroTag ?? ad.id,
                          child: PageView(
                            onPageChanged: (i) => setState(() => _page = i),
                            children: [
                              if (ad.images.isEmpty) SouqCover(ad: ad),
                              for (final img in ad.images) _Photo(path: img),
                            ],
                          ),
                        ),
                        if (ad.images.length > 1)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_page + 1}/${ad.images.length}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SouqFormat.sar(ad.price, ar: l10n.ar),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.goldSoft,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (ad.isNegotiable)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.negotiable,
                            style: const TextStyle(color: AppColors.green),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        ad.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (ad.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          ad.subtitle,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                      if (ad.video.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.videocam_rounded, size: 18),
                              SizedBox(width: 6),
                              Text('Video'),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '${ad.city}${ad.district != null ? ' · ${ad.district}' : ''} · ${SouqFormat.relativeTime(ad.createdAt, ar: l10n.ar)} · ${ad.views} views',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _Spec(Icons.verified_outlined, SouqFormat.conditionLabel(ad.condition, ar: l10n.ar)),
                          if (ad.year != null) _Spec(Icons.event_rounded, '${ad.year}'),
                          if (ad.mileage != null)
                            _Spec(Icons.speed_rounded, SouqFormat.km(ad.mileage)),
                          if (ad.transmission != null)
                            _Spec(Icons.settings_rounded, ad.transmission!),
                          if (ad.fuel != null) _Spec(Icons.local_gas_station, ad.fuel!),
                          if (ad.color != null) _Spec(Icons.palette_outlined, ad.color!),
                          if (ad.bodyType != null)
                            _Spec(Icons.directions_car_filled_outlined, ad.bodyType!),
                          if (ad.attributes['engine'] != null)
                            _Spec(Icons.memory_rounded, '${ad.attributes['engine']}'),
                          if (ad.attributes['origin'] != null)
                            _Spec(Icons.public_rounded, '${ad.attributes['origin']}'),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        l10n.details,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ad.description,
                        style: const TextStyle(height: 1.45, fontSize: 15),
                      ),
                      const SizedBox(height: 22),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.stroke),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.chip,
                            child: Text(
                              ad.seller.name.characters.first.toUpperCase(),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ad.seller.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (ad.seller.isVerified)
                                const Padding(
                                  padding: EdgeInsetsDirectional.only(start: 6),
                                  child: Icon(
                                    Icons.verified_rounded,
                                    size: 18,
                                    color: AppColors.green,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(l10n.seller),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(height: 12),
                      ExpansionTile(
                        title: Text(l10n.safety),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(l10n.safetyBody),
                          ),
                        ],
                      ),
                      if (ad.originalUrl != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.open_in_new_rounded),
                          title: Text(
                            ad.isExpat ? l10n.viewOriginalExpat : l10n.viewOriginal,
                          ),
                          onTap: () => launchUrl(
                            Uri.parse(ad.originalUrl!),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.flag_outlined),
                        title: Text(l10n.report),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thanks — this listing was flagged on this device.'),
                            ),
                          );
                        },
                      ),
                      if (_similar.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.similar,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 268,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _similar.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, i) => SizedBox(
                              width: 196,
                              child: SouqAdCard(
                                ad: _similar[i],
                                heroPrefix: 'sim',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: MediaQuery.paddingOf(context).bottom + 12,
            child: GlassBar(
              child: Row(
                children: [
                  if (ad.contact.call && ad.seller.phone != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => launchUrl(Uri.parse('tel:${ad.seller.phone}')),
                        icon: const Icon(Icons.call_rounded),
                        label: Text(l10n.call),
                      ),
                    ),
                  if (ad.contact.whatsapp &&
                      (ad.seller.whatsapp ?? ad.seller.phone) != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          final phone =
                              (ad.seller.whatsapp ?? ad.seller.phone)!
                                  .replaceAll(RegExp(r'\D'), '');
                          final text = Uri.encodeComponent(l10n.interested(ad.title));
                          launchUrl(
                            Uri.parse('https://wa.me/$phone?text=$text'),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        icon: const Icon(Icons.chat_rounded),
                        label: Text(l10n.whatsapp),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (!await ensureSouqSignedIn(context)) return;
                        if (!context.mounted) return;
                        final me = AuthSession.instance.user?.id;
                        if (me != null && me == ad.seller.id) {
                          openCard(context, SouqChatListScreen(adId: ad.id));
                          return;
                        }
                        try {
                          await SouqController.instance.repo.openChat(ad: ad);
                          if (!context.mounted) return;
                          openCard(
                            context,
                            SouqChatThreadScreen(adId: ad.id),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      },
                      icon: const Icon(Icons.forum_outlined),
                      label: Text(l10n.chat),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openGallery(Ad ad) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => _Gallery(ad: ad, index: _page),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover);
    }
    final f = File(path);
    if (f.existsSync()) return Image.file(f, fit: BoxFit.cover);
    return const ColoredBox(color: AppColors.chip);
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: color ?? Colors.white),
          ),
        ),
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.ad, required this.index});
  final Ad ad;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (d) {
        if (d.primaryVelocity != null && d.primaryVelocity! > 240) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: PageView(
          controller: PageController(initialPage: index),
          children: [
            if (ad.images.isEmpty)
              InteractiveViewer(child: SouqCover(ad: ad)),
            for (final img in ad.images)
              InteractiveViewer(child: _Photo(path: img)),
          ],
        ),
      ),
    );
  }
}

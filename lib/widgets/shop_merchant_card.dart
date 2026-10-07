import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_analytics.dart';
import '../models/shop.dart';
import '../screens/shop_merchant_screen.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

class ShopMerchantCard extends StatelessWidget {
  const ShopMerchantCard({super.key, required this.merchant});

  final ShopMerchant merchant;

  String? _downloadUrl(TargetPlatform platform) {
    if (platform == TargetPlatform.iOS) {
      return merchant.appStoreUrl.isNotEmpty ? merchant.appStoreUrl : null;
    }
    return merchant.playStoreUrl.isNotEmpty ? merchant.playStoreUrl : null;
  }

  Future<void> _openStore(String raw) async {
    await launchUrl(Uri.parse(raw), mode: LaunchMode.externalApplication);
  }

  void _openDetail(BuildContext context) {
    AppAnalytics.instance.log(
      event: 'shop_open',
      section: 'shops',
      targetId: merchant.id,
      targetTitle: merchant.name,
    );
    openCard(context, ShopMerchantScreen(merchant: merchant));
  }

  @override
  Widget build(BuildContext context) {
    final thumb = merchant.icon.isNotEmpty ? merchant.icon : merchant.image;
    final download = _downloadUrl(Theme.of(context).platform);
    final coupons = merchant.coupons.length;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        children: [
          Row(
            children: [
              _AppThumb(url: thumb),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (merchant.blurb.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        merchant.blurb,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (download != null) ...[
                const SizedBox(width: 8),
                _IconAction(
                  icon: Icons.file_download_outlined,
                  tooltip: 'App',
                  onTap: () => _openStore(download),
                ),
              ],
            ],
          ),
          if (coupons > 0) ...[
            const SizedBox(height: 10),
            _GetCouponBar(
              count: coupons,
              onTap: () => _openDetail(context),
            ),
          ],
        ],
      ),
    );
  }
}

class ShopFilterBar extends StatelessWidget {
  const ShopFilterBar({
    super.key,
    required this.filters,
    required this.onSelected,
  });

  final List<ShopFilter> filters;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter.selected;
          return PressableScale(
            onTap: () => onSelected(filter.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.gold : AppColors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? AppColors.gold : AppColors.stroke,
                ),
              ),
              child: Text(
                '${filter.label} ${filter.count}',
                style: TextStyle(
                  color: selected ? AppColors.onDark : AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ShopSearchField extends StatelessWidget {
  const ShopSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'Search shops',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded, color: AppColors.muted),
              ),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
      ),
    );
  }
}

class _AppThumb extends StatelessWidget {
  const _AppThumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url.isEmpty
            ? const ColoredBox(
                color: AppColors.bg,
                child: Icon(Icons.storefront_rounded, color: AppColors.gold, size: 20),
              )
            : CachedNetworkImage(
                imageUrl: url,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                memCacheWidth: 88,
                placeholder: (_, __) => const ColoredBox(color: AppColors.bg),
                errorWidget: (_, __, ___) => const ColoredBox(
                  color: AppColors.bg,
                  child: Icon(Icons.storefront_rounded, color: AppColors.gold, size: 20),
                ),
              ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.stroke),
          ),
          child: Icon(icon, size: 16, color: AppColors.gold),
        ),
      ),
    );
  }
}

class _GetCouponBar extends StatelessWidget {
  const _GetCouponBar({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.gold),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Get coupon',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.gold,
                ),
              ),
            ),
            Text(
              count == 1 ? '1 coupon' : '$count coupons',
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

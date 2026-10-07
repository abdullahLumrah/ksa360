import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_analytics.dart';
import '../models/shop.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';

class ShopMerchantScreen extends StatelessWidget {
  const ShopMerchantScreen({super.key, required this.merchant});

  final ShopMerchant merchant;

  Future<void> _open(String raw) async {
    if (raw.isEmpty) return;
    await launchUrl(Uri.parse(raw), mode: LaunchMode.externalApplication);
  }

  String? _downloadUrl(TargetPlatform platform) {
    if (platform == TargetPlatform.iOS) {
      return merchant.appStoreUrl.isNotEmpty ? merchant.appStoreUrl : null;
    }
    return merchant.playStoreUrl.isNotEmpty ? merchant.playStoreUrl : null;
  }

  @override
  Widget build(BuildContext context) {
    final download = _downloadUrl(Theme.of(context).platform);
    final thumb = merchant.icon.isNotEmpty ? merchant.icon : merchant.image;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(merchant.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: thumb.isEmpty
                    ? const SizedBox(
                        width: 72,
                        height: 72,
                        child: ColoredBox(
                          color: AppColors.card,
                          child: Icon(Icons.storefront_rounded, color: AppColors.gold),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: thumb,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        height: 1.15,
                      ),
                    ),
                    if (merchant.blurb.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        merchant.blurb,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.35,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (download != null)
                _TextLink(
                  label: 'App',
                  icon: Icons.file_download_outlined,
                  onTap: () => _open(download),
                ),
              if (download != null && merchant.website.isNotEmpty)
                const SizedBox(width: 16),
              if (merchant.website.isNotEmpty)
                _TextLink(
                  label: 'Website',
                  icon: Icons.public_outlined,
                  onTap: () => _open(merchant.website),
                ),
            ],
          ),
          if (merchant.coupons.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text(
              'Coupons',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 10),
            for (final coupon in merchant.coupons) ...[
              _CouponDetail(coupon: coupon),
              const SizedBox(height: 10),
            ],
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 22),
              child: Text(
                'No coupon code for this shop right now.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponDetail extends StatelessWidget {
  const _CouponDetail({required this.coupon});

  final ShopCoupon coupon;

  Future<void> _copy(BuildContext context) async {
    if (coupon.code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: coupon.code));
    HapticFeedback.selectionClick();
    AppAnalytics.instance.log(
      event: 'shop_coupon_copy',
      section: 'shops',
      targetId: coupon.id,
      targetTitle: coupon.code,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${coupon.code} copied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (coupon.title.isNotEmpty)
            Text(
              coupon.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          if (coupon.detail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              coupon.detail,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          if (coupon.code.isNotEmpty) ...[
            const SizedBox(height: 12),
            PressableScale(
              onTap: () => _copy(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        coupon.code,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const Icon(Icons.copy_rounded, size: 18, color: AppColors.gold),
                    const SizedBox(width: 6),
                    const Text(
                      'Copy',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

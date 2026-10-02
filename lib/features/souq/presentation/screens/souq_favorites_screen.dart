import 'package:flutter/material.dart';

import '../../../../theme/app_theme.dart';
import '../../domain/souq_models.dart';
import '../souq_controller.dart';
import '../souq_l10n.dart';
import '../widgets/souq_ad_card.dart';
import '../widgets/souq_widgets.dart';

class SouqFavoritesScreen extends StatefulWidget {
  const SouqFavoritesScreen({super.key});

  @override
  State<SouqFavoritesScreen> createState() => _SouqFavoritesScreenState();
}

class _SouqFavoritesScreenState extends State<SouqFavoritesScreen> {
  List<Ad> _ads = [];

  @override
  void initState() {
    super.initState();
    _load();
    SouqController.instance.addListener(_load);
  }

  Future<void> _load() async {
    await SouqController.instance.ensureReady();
    final ads = await SouqController.instance.favoriteAds();
    if (mounted) setState(() => _ads = ads);
  }

  @override
  void dispose() {
    SouqController.instance.removeListener(_load);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SouqL10n.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(l10n.favorites)),
      body: _ads.isEmpty
          ? SouqEmpty(title: l10n.noFavorites)
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.62,
              ),
              itemCount: _ads.length,
              itemBuilder: (context, i) => SouqAdCard(
                ad: _ads[i],
                heroPrefix: 'fav',
              ),
            ),
    );
  }
}

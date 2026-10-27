import 'package:flutter/material.dart';

import '../../../data/auth_session.dart';
import '../../../screens/auth_sheet.dart';
import '../../../widgets/motion.dart';
import '../domain/souq_models.dart';
import 'screens/souq_chat_screens.dart';
import 'screens/souq_favorites_screen.dart';
import 'screens/souq_my_ads_screen.dart';
import 'screens/souq_post_wizard_screen.dart';
import 'souq_controller.dart';

Future<void> openSouqSell(
  BuildContext context, {
  String? categoryId,
}) async {
  if (!AuthSession.instance.isSignedIn) {
    await showAuthSheet(context);
    if (!context.mounted) return;
    if (!AuthSession.instance.isSignedIn) return;
  }
  if (!context.mounted) return;
  openCard(context, SouqPostWizardScreen(initialCategoryId: categoryId));
}

Future<bool> ensureSouqSignedIn(BuildContext context) async {
  if (AuthSession.instance.isSignedIn) return true;
  await showAuthSheet(context);
  if (!context.mounted) return false;
  return AuthSession.instance.isSignedIn;
}

Future<void> openSouqAdChat(BuildContext context, {required Ad ad}) async {
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
    openCard(context, SouqChatThreadScreen(adId: ad.id));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }
}

Future<void> openSouqChats(BuildContext context, {String? adId}) async {
  if (!await ensureSouqSignedIn(context)) return;
  if (!context.mounted) return;
  openCard(context, SouqChatListScreen(adId: adId));
}

Future<void> openSouqFavorites(BuildContext context) async {
  if (!await ensureSouqSignedIn(context)) return;
  if (!context.mounted) return;
  openCard(context, const SouqFavoritesScreen());
}

Future<void> openSouqMyAds(BuildContext context) async {
  if (!await ensureSouqSignedIn(context)) return;
  if (!context.mounted) return;
  openCard(context, const SouqMyAdsScreen());
}

Future<bool> toggleSouqFavorite(BuildContext context, String id) async {
  if (!await ensureSouqSignedIn(context)) return false;
  await SouqController.instance.toggleFavorite(id);
  return true;
}

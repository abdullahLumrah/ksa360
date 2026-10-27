import 'package:flutter/material.dart';

import '../data/auth_session.dart';
import '../data/block_store.dart';
import '../data/community_repository.dart';
import '../features/souq/presentation/souq_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/community.dart';
import '../theme/app_theme.dart';
import 'auth_sheet.dart';
import 'community_report_sheet.dart';

Future<void> showCommunityPostActions(
  BuildContext context, {
  required CommunityPost post,
  VoidCallback? onBlocked,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      final me = AuthSession.instance.user?.id;
      final mine = me != null && me == post.authorId;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stroke,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(l10n.reportPost),
                onTap: () async {
                  Navigator.pop(ctx);
                  await showCommunityReportSheet(
                    context,
                    targetType: 'post',
                    targetId: post.id,
                    reportedUserId: post.authorId,
                    communityId: post.communityId,
                    title: l10n.reportPost,
                  );
                },
              ),
              if (!mine) ...[
                ListTile(
                  leading: const Icon(Icons.person_off_outlined),
                  title: Text(l10n.reportUser),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await showCommunityReportSheet(
                      context,
                      targetType: 'user',
                      targetId: post.authorId,
                      reportedUserId: post.authorId,
                      communityId: post.communityId,
                      title: '${l10n.reportUser} · ${post.authorName}',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block_rounded, color: AppColors.red),
                  title: Text(
                    l10n.blockUser,
                    style: const TextStyle(color: AppColors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final blocked = await blockUserFlow(
                      context,
                      userId: post.authorId,
                      userName: post.authorName,
                      targetType: 'post',
                      targetId: post.id,
                      communityId: post.communityId,
                    );
                    if (blocked) onBlocked?.call();
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Future<bool> blockUserFlow(
  BuildContext context, {
  required String userId,
  required String userName,
  String adId = '',
  String targetType = 'user',
  String targetId = '',
  String communityId = '',
}) async {
  if (!AuthSession.instance.isSignedIn) {
    await showAuthSheet(context);
  }
  if (!context.mounted || !AuthSession.instance.isSignedIn) return false;
  if (userId.isEmpty && adId.trim().isEmpty) return false;
  if (BlockStore.isAppUserId(userId) &&
      userId == AuthSession.instance.user?.id) {
    return false;
  }
  final alreadyBlocked = BlockStore.instance.isBlocked(userId) ||
      BlockStore.instance.isBlockedAd(adId);
  if (alreadyBlocked) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).userBlocked)),
    );
    return true;
  }
  final l10n = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.blockUserConfirm),
        content: Text(l10n.blockUserConfirmBody(userName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: Text(l10n.blockUser),
          ),
        ],
      );
    },
  );
  if (ok != true || !context.mounted) return false;
  try {
    await BlockStore.instance.block(
      userId: userId,
      adId: adId,
      reason: 'Block user',
      details: 'Blocked $userName from the app',
      targetType: targetType,
      targetId: targetId.isNotEmpty ? targetId : userId,
      communityId: communityId,
    );
    CommunityRepository.instance.hideAuthor(userId);
    SouqController.instance.hideBlockedSellers();
    if (!context.mounted) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.userBlocked)),
    );
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
    );
    return false;
  }
}

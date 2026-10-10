import 'package:flutter/material.dart';

import '../data/community_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_filter_chip.dart';

Future<bool> showCommunityReportSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
  String reportedUserId = '',
  String communityId = '',
  String title = 'Report',
}) async {
  final reasons = CommunityRepository.instance.reportReasons;
  String reason = reasons.isNotEmpty ? reasons.first : 'Other';
  final details = TextEditingController();
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: StatefulBuilder(
          builder: (ctx, setModal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.stroke,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Tell us why. Our team reviews every report.',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: reasons.map((item) {
                    final on = item == reason;
                    return AppFilterChip(
                      label: item,
                      selected: on,
                      onSelected: (_) => setModal(() => reason = item),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: details,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'Optional details',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        await CommunityRepository.instance.report(
                          targetType: targetType,
                          targetId: targetId,
                          reason: reason,
                          details: details.text.trim(),
                          reportedUserId: reportedUserId,
                          communityId: communityId,
                        );
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Exception: ', ''),
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Submit report'),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
  details.dispose();
  return ok == true;
}

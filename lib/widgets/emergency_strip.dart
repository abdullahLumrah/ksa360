import 'package:flutter/material.dart';

import '../data/dial.dart';
import '../data/emergencies.dart';
import '../data/healthcare_repository.dart';
import '../theme/app_theme.dart';
import 'motion.dart';

class EmergencyStrip extends StatelessWidget {
  const EmergencyStrip({super.key, this.onSeeAll});

  final VoidCallback? onSeeAll;

  static const _cardHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HealthcareRepository.instance,
      builder: (context, _) {
        final api = HealthcareRepository.instance.hotlines;
        final lines = (api.isNotEmpty
                ? [
                    for (final line in api)
                      EmergencyNumber(
                        label: line.label,
                        number: line.number,
                        detail: line.detail,
                      ),
                  ]
                : EmergencyData.hotlines)
            .take(4)
            .toList();
        return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Emergency',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: _cardHeight,
            child: Row(
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _EmergencyChip(item: lines[i])),
                ],
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

class _EmergencyChip extends StatelessWidget {
  const _EmergencyChip({required this.item});

  final EmergencyNumber item;

  @override
  Widget build(BuildContext context) {
    final panic = item.number == '911';
    // SizedBox.expand fills this tight slot. PressableScale's Stack/Transform
    // only sizes to its child, so the row height + Expanded width must be tight
    // before PressableScale (a loose Row+Expanded crushed the cards before).
    return SizedBox(
      height: EmergencyStrip._cardHeight,
      width: double.infinity,
      child: PressableScale(
        borderRadius: BorderRadius.circular(14),
        onTap: () => callNumber(item.number),
        child: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: panic
                  ? const LinearGradient(
                      colors: [Color(0xFFB42318), AppColors.red],
                    )
                  : null,
              color: panic ? null : AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: panic ? Colors.transparent : AppColors.stroke,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.number,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: panic ? Colors.white : AppColors.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      height: 1.1,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    panic ? 'SOS' : item.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: panic ? Colors.white70 : AppColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

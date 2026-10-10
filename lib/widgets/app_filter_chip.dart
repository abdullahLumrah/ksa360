import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Dark selected fill + white label (no checkmark) for filter chips app-wide.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.compact = false,
    this.padding,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final bool compact;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: onSelected,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      selectedColor: AppColors.greenDeep,
      backgroundColor: AppColors.card,
      side: BorderSide(
        color: selected ? AppColors.greenDeep : AppColors.stroke,
      ),
      labelStyle: TextStyle(
        fontSize: compact ? 11 : 12,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColors.navy,
      ),
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: compact ? 4 : 6,
            vertical: 0,
          ),
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.greenDeep;
        }
        return AppColors.card;
      }),
    );
  }
}

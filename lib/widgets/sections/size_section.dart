import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/color_utils.dart';
import '../../data/cake_options.dart';
import '../../models/cake_config.dart';
import '../common/section.dart';
import '../common/light_chip.dart';

/// Section 1 — Cake size selector
class SizeSection extends StatelessWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onChanged;

  const SizeSection({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final current = cakeSizes
        .where((s) => (s.radius - config.cakeRadius).abs() < 0.03)
        .firstOrNull;

    return Section(
      number: 1,
      title: 'SIZE',
      arabicTitle: 'المقاس',
      subtitle: 'اختر الحجم المثالي لمناسبتك',
      trailing: current != null ? TextBadge(text: current.serves) : null,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: cakeSizes.map((size) {
            final selected = current?.label == size.label;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _SizeChip(
                label: size.label,
                selected: selected,
                onTap: () => onChanged(config.copyWith(
                  cakeRadius: size.radius,
                  cakeHeight: size.height,
                )),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SizeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            else
              AppColors.cardShadow,
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textMid,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

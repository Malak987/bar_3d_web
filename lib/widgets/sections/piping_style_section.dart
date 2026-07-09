import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/cake_config.dart';
import '../common/section.dart';

/// Section 4 — Piping coverage area
class PipingStyleSection extends StatelessWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onChanged;

  const PipingStyleSection({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Section(
      number: 4,
      title: 'COVERAGE',
      arabicTitle: 'مساحة التزيين',
      subtitle: 'حدد مكان التزيين بدقة على الكيكة',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _CoverageCard(
                  icon: '🔝',
                  title: 'حافة القمة',
                  subtitle: 'تزيين الحافة العلوية فقط',
                  selected: config.pipingPlacement == 'border',
                  onTap: () => onChanged(config.copyWith(
                    pipingPlacement: 'border',
                    edgeTop: true,
                    edgeBottom: false,
                    pipingColorCount: 1, // حافة القمة فقط = لون واحد إجباري
                  )),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CoverageCard(
                  icon: '✨',
                  title: 'تغطية كاملة',
                  subtitle: 'تزيين القمة والجوانب بالكامل',
                  selected: config.pipingPlacement == 'full',
                  onTap: () => onChanged(config.copyWith(
                    pipingPlacement: 'full',
                    edgeTop: false,
                    edgeBottom: false,
                  )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CoverageCard(
            icon: '⭕',
            title: 'حافة القمة والسفلية',
            subtitle: 'نفس شكل التزيين على الحافة العلوية والسفلية',
            selected: config.pipingPlacement == 'edges',
            onTap: () => onChanged(config.copyWith(
              pipingPlacement: 'edges',
              edgeTop: true,
              edgeBottom: true,
              // القمة والقاع = لون واحد أو لونين بس (مش 3)
              pipingColorCount: config.pipingColorCount.clamp(1, 2),
            )),
          ),
        ],
      ),
    );
  }
}

class _CoverageCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _CoverageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 5),
              )
            else
              AppColors.cardShadow,
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: selected
                    ? Colors.white.withOpacity(0.7)
                    : AppColors.textLight,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
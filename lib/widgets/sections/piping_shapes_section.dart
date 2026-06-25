import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/cake_options.dart';
import '../../models/cake_config.dart';
import '../../models/cake_meta.dart';
import '../common/section.dart';

/// Section 6 — 17 piping shapes grid
class PipingShapesSection extends StatelessWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onChanged;

  const PipingShapesSection({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Section(
      number: 6,
      title: 'SHAPE',
      arabicTitle: 'شكل التزيين',
      subtitle: pipingOptions.isEmpty ? 'لا توجد أشكال تزيين متاحة حالياً' : 'اختر شكل التزيين المناسب لذوقك',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: pipingOptions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (_, i) {
          final item = pipingOptions[i];
          return _PipingCard(
            item: item,
            selected: config.pipingType == item.id,
            onTap: () => onChanged(config.copyWith(pipingType: item.id)),
          );
        },
      ),
    );
  }
}

class _PipingCard extends StatelessWidget {
  final PipingMeta item;
  final bool selected;
  final VoidCallback onTap;

  const _PipingCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
            BoxShadow(
              color: AppColors.teal.withOpacity(0.55),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: selected ? 6 : 4,
                height: selected ? 6 : 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? Colors.white.withOpacity(0.6)
                      : AppColors.teal.withOpacity(0.3),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (selected)
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.teal.withOpacity(0.25),
                          border: Border.all(
                            color: AppColors.teal.withOpacity(0.5),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item.icon,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      )
                    else
                      Text(
                        item.icon,
                        style: const TextStyle(fontSize: 22),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.primary,
                        fontSize: 9.5,
                        fontWeight:
                        selected ? FontWeight.w900 : FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// 1 / 2 / 3 segmented selector (Arabic numerals)
class CountSelector extends StatelessWidget {
  final int count;
  final ValueChanged<int> onChanged;

  const CountSelector({
    super.key,
    required this.count,
    required this.onChanged,
  });

  static const _options = [(1, '١'), (2, '٢'), (3, '٣')];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _options.map((o) {
          return _CountBtn(
            value: o.$1,
            label: o.$2,
            selected: count == o.$1,
            onTap: () => onChanged(o.$1),
          );
        }).toList(),
      ),
    );
  }
}

class _CountBtn extends StatelessWidget {
  final int value;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CountBtn({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textLight,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

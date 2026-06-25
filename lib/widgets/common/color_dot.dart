import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/color_utils.dart';

/// Single circular swatch
class ColorDot extends StatelessWidget {
  final String hex;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const ColorDot({
    super.key,
    required this.hex,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(hex);
    return Tooltip(
      message: name,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: selected ? 34 : 30,
          height: selected ? 34 : 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.primary : Colors.white,
              width: selected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(selected ? 0.55 : 0.2),
                blurRadius: selected ? 10 : 4,
              ),
              const BoxShadow(
                color: Colors.white54,
                blurRadius: 3,
                offset: Offset(-1, -1),
              ),
            ],
          ),
          child: selected
              ? Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: isDarkColor(color) ? Colors.white : AppColors.primary,
                )
              : null,
        ),
      ),
    );
  }
}

/// Tiny swatch used by quick-color rows
class MiniColorDot extends StatelessWidget {
  final String hex;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  const MiniColorDot({
    super.key,
    required this.hex,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(hex);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.teal : Colors.transparent,
              width: selected ? 2.5 : 0,
            ),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.4), blurRadius: selected ? 8 : 2),
            ],
          ),
          child: selected
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

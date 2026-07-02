import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/cake_options.dart';
import '../../models/cake_config.dart';
import '../../models/cake_meta.dart';
import '../common/section.dart';

/// Section 2 — Cake base flavor (chocolate / vanilla / mix)
class BaseFlavorSection extends StatelessWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onChanged;

  const BaseFlavorSection({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortedSizes = List<CakeSizeOption>.from(cakeSizes)
      ..sort((a, b) => a.radius.compareTo(b.radius));
    final currentSize = sortedSizes.where((s) => (s.radius - config.cakeRadius).abs() < 0.05).firstOrNull;
    final is10 = (currentSize != null && (currentSize.label.contains('10') || currentSize.id == '10' || currentSize.label.contains('١٠') || currentSize == sortedSizes.firstOrNull));

    var allowedFlavors = is10
        ? baseFlavors.where((f) {
      final lbl = '${f.id} ${f.label} ${f.arabicLabel}'.toLowerCase();
      if (lbl.contains('mix') || lbl.contains('ميكس') || lbl.contains('نصف') || lbl.contains('مشكل') || lbl.contains('half') || lbl.contains('duo') || lbl.contains('خليط')) {
        return false;
      }
      return lbl.contains('choc') || lbl.contains('vanil') || lbl.contains('شيكولات') || lbl.contains('فانيلي');
    }).toList()
        : baseFlavors;

    if (is10 && allowedFlavors.isEmpty) {
      allowedFlavors = baseFlavors.where((f) {
        final lbl = '${f.id} ${f.label} ${f.arabicLabel}'.toLowerCase();
        return !(lbl.contains('mix') || lbl.contains('ميكس') || lbl.contains('نصف') || lbl.contains('half'));
      }).toList();
    }

    final listToShow = allowedFlavors.isNotEmpty ? allowedFlavors : baseFlavors;

    return Section(
      number: 2,
      title: 'BASE FLAVOR',
      arabicTitle: 'نكهة القاعدة',
      subtitle: is10
          ? 'مقاس 10 متاح به اختيار شيكولاتة أو فانيليا فقط (غير متاح الميكس)'
          : (listToShow.isEmpty ? 'لا توجد نكهات متاحة حالياً' : 'اختر النكهة المناسبة لتصميمك'),
      child: Row(
        children: listToShow.map((f) {
          final selected = config.baseFlavor == f.id;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: _FlavorCircle(
                flavor: f,
                selected: selected,
                onTap: () => onChanged(config.copyWith(baseFlavor: f.id)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FlavorCircle extends StatelessWidget {
  final BaseFlavor flavor;
  final bool selected;
  final VoidCallback onTap;

  const _FlavorCircle({
    required this.flavor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = _parseColor(flavor.color);
    final emoji = Text(
      flavor.icon.isNotEmpty ? flavor.icon : '🎂',
      style: const TextStyle(fontSize: 24),
    );

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? 72 : 64,
            height: selected ? 72 : 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 3 : 1.5,
              ),
              boxShadow: selected
                  ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(child: emoji),
          ),
          const SizedBox(height: 8),
          Text(
            flavor.arabicLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textLight,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
          if (selected) ...[
            const SizedBox(height: 4),
            Container(
              width: 20,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _parseColor(String hex) {
  var value = hex.trim().replaceAll('#', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.tryParse(value, radix: 16) ?? 0xFFFFFFFF);
}

class _MixPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width / 2, size.height),
      Paint()..color = const Color(0xFF3D1A0A),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height),
      Paint()..color = const Color(0xFFF5DEB3),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

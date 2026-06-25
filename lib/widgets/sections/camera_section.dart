import 'package:flutter/material.dart';
import '../../models/cake_config.dart';
import '../common/section.dart';
import '../common/light_chip.dart';

/// Section 9 — Camera reset + auto-rotate toggle
class CameraSection extends StatelessWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onChanged;
  final VoidCallback onResetCamera;

  const CameraSection({
    super.key,
    required this.config,
    required this.onChanged,
    required this.onResetCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Section(
      number: 9,
      title: 'VIEW',
      arabicTitle: 'التحكم بالعرض',
      subtitle: 'دوّر وكبّر لرؤية كل التفاصيل',
      child: Row(
        children: [
          Expanded(
            child: LightChip(
              label: '↺ ضبط الكاميرا',
              selected: false,
              onTap: onResetCamera,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LightChip(
              label: config.autoRotate ? '⏸ إيقاف' : '▶ دوران',
              selected: config.autoRotate,
              onTap: () => onChanged(
                config.copyWith(autoRotate: !config.autoRotate),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

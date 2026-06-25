import 'package:flutter/material.dart';
import '../../models/cake_config.dart';
import '../common/section.dart';
import '../common/count_selector.dart';
import '../common/grouped_color_row.dart';

/// Section 3 — Cake gradient colors (1 / 2 / 3)
class CakeColorsSection extends StatelessWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onChanged;

  const CakeColorsSection({
    super.key,
    required this.config,
    required this.onChanged,
  });

  String _labelFor(int i, int total) {
    if (total == 1) return 'لون الكيكة';
    if (i == 0) return 'لون القمة';
    if (i == total - 1) return 'لون القاعدة';
    return 'لون الوسط';
  }

  // UI top→bottom maps to data bottom→top
  int _dataIndex(int uiIndex, int total) => total - 1 - uiIndex;

  @override
  Widget build(BuildContext context) {
    final total = config.gradientColorCount;

    return Section(
      number: 3,
      title: 'CAKE COLORS',
      arabicTitle: 'ألوان الكيكة',
      subtitle: '✨ اختر لون الكيكة بشكل احترافي',
      trailing: CountSelector(
        count: total,
        onChanged: (v) => onChanged(config.copyWith(gradientColorCount: v)),
      ),
      child: Column(
        children: List.generate(total, (uiIndex) {
          final dataIndex = _dataIndex(uiIndex, total);
          final hex = dataIndex < config.colors.length
              ? config.colors[dataIndex]
              : '#ffffff';
          return Padding(
            padding: EdgeInsets.only(bottom: uiIndex < total - 1 ? 16 : 0),
            child: GroupedColorRow(
              label: _labelFor(uiIndex, total),
              selectedHex: hex,
              onSelect: (h) {
                final next = List<String>.from(config.colors);
                while (next.length < 3) next.add('#ffffff');
                next[dataIndex] = h;
                onChanged(config.copyWith(colors: List.unmodifiable(next)));
              },
            ),
          );
        }),
      ),
    );
  }
}

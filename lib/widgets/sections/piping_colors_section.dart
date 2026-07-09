import 'package:flutter/material.dart';
import '../../models/cake_config.dart';
import '../common/section.dart';
import '../common/count_selector.dart';
import '../common/grouped_color_row.dart';

/// Section 5 — Piping gradient colors
class PipingColorsSection extends StatelessWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onChanged;

  const PipingColorsSection({
    super.key,
    required this.config,
    required this.onChanged,
  });

  String _labelFor(int i, int total) {
    if (total == 1) return 'لون التزيين';
    if (i == 0) return 'لون تزيين القمة';
    if (i == total - 1) return 'لون تزيين القاعدة';
    return 'لون تزيين الوسط';
  }

  int _dataIndex(int uiIndex, int total) => total - 1 - uiIndex;

  /// حافة القمة فقط → لون واحد إجباري
  /// حافة القمة والسفلية → لون واحد أو لونين (فوق/تحت)
  /// تغطية كاملة → لحد 3 ألوان زي المعتاد
  int _maxColorsFor(String placement) {
    switch (placement) {
      case 'border':
        return 1;
      case 'edges':
        return 2;
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = _maxColorsFor(config.pipingPlacement);
    final total = config.pipingColorCount.clamp(1, maxCount);

    return Section(
      number: 5,
      title: 'DECORATION COLORS',
      arabicTitle: 'ألوان التزيين',
      subtitle: 'نسق ألوان الكريمة مع الكيكة باحترافية',
      trailing: maxCount == 1
          ? null // لون واحد إجباري — مفيش داعي للمحدد خالص
          : CountSelector(
        count: total,
        maxCount: maxCount,
        onChanged: (v) => onChanged(config.copyWith(pipingColorCount: v)),
      ),
      child: Column(
        children: List.generate(total, (uiIndex) {
          final dataIndex = _dataIndex(uiIndex, total);
          final hex = dataIndex < config.pipingColors.length
              ? config.pipingColors[dataIndex]
              : '#ffffff';
          return Padding(
            padding: EdgeInsets.only(bottom: uiIndex < total - 1 ? 16 : 0),
            child: GroupedColorRow(
              label: _labelFor(uiIndex, total),
              selectedHex: hex,
              onSelect: (h) {
                final next = List<String>.from(config.pipingColors);
                while (next.length < 3) next.add('#ffffff');
                next[dataIndex] = h;
                onChanged(config.copyWith(
                  pipingColors: List.unmodifiable(next),
                  pipingColor: next.first,
                ));
              },
            ),
          );
        }),
      ),
    );
  }
}
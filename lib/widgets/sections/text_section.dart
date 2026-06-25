import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/cake_config.dart';
import '../common/section.dart';
import '../common/light_chip.dart';
import '../common/light_slider.dart';
import '../common/grouped_color_row.dart';

/// Section 8 — Custom message on top of cake
class TextSection extends StatelessWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onChanged;

  const TextSection({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Section(
      number: 8,
      title: 'MESSAGE',
      arabicTitle: 'النص المخصص',
      subtitle: 'اكتب رسالتك بخط احترافي مميز',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _textInput(),
          if (config.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            GroupedColorRow(
              label: 'لون النص',
              selectedHex: config.textColor,
              onSelect: (v) => onChanged(config.copyWith(textColor: v)),
            ),
            const SizedBox(height: 16),
            const FieldLabel('شكل الخط'),
            const SizedBox(height: 8),
            _fontStyleRow(),
            const SizedBox(height: 16),
            const FieldLabel('مكان النص'),
            const SizedBox(height: 8),
            _positionRow(),
            const SizedBox(height: 16),
            LightSlider(
              label: 'حجم النص',
              value: config.textSize,
              min: 0.5,
              max: 2.5,
              display: '${config.textSize.toStringAsFixed(1)}x',
              onChanged: (v) => onChanged(config.copyWith(textSize: v)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _textInput() {
    return TextField(
      controller: TextEditingController(text: config.text)
        ..selection = TextSelection.collapsed(offset: config.text.length),
      onChanged: (v) => onChanged(config.copyWith(text: v)),
      maxLength: 30,
      textDirection: TextDirection.rtl,
      style: const TextStyle(color: AppColors.primary, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'اكتب رسالتك هنا...',
        hintStyle: const TextStyle(color: AppColors.hint, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        counterStyle: const TextStyle(color: AppColors.hint),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _fontStyleRow() {
    final styles = [
      ('عادي',     'normal'),
      ('كلاسيكي', 'amiri'),
      ('يد حرة',   'cursive'),
    ];
    return Row(
      children: [
        for (var i = 0; i < styles.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: LightChip(
              label: styles[i].$1,
              selected: config.fontStyle == styles[i].$2,
              onTap: () => onChanged(config.copyWith(fontStyle: styles[i].$2)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _positionRow() {
    final positions = [
      ('أعلى', 'top'),
      ('وسط',  'center'),
      ('أسفل', 'bottom'),
    ];
    return Row(
      children: [
        for (var i = 0; i < positions.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: LightChip(
              label: positions[i].$1,
              selected: config.textPosition == positions[i].$2,
              onTap: () =>
                  onChanged(config.copyWith(textPosition: positions[i].$2)),
            ),
          ),
        ],
      ],
    );
  }
}

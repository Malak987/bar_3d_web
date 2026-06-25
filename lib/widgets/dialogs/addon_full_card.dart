import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/color_utils.dart';
import '../../data/addon_options.dart';
import '../../models/cake_meta.dart';

/// ──────────────────────────────────────────────────────
/// AddonFullCard
///   • toggle switch
///   • quick color row (or fixed sprinkle colors)
///   • optional text input (secret-message addon)
/// ──────────────────────────────────────────────────────
class AddonFullCard extends StatelessWidget {
  final AddonMeta addon;
  final bool selected;
  final String color;
  final VoidCallback onToggle;
  final ValueChanged<String>? onColorChanged;
  final String? secretMessageText;
  final ValueChanged<String>? onSecretMsgChanged;

  const AddonFullCard({
    super.key,
    required this.addon,
    required this.selected,
    required this.color,
    required this.onToggle,
    this.onColorChanged,
    this.secretMessageText,
    this.onSecretMsgChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                ),
              ],
      ),
      child: Column(
        children: [
          _headerRow(),
          if (selected && onColorChanged != null) ...[
            const SizedBox(height: 12),
            _colorPickerRow(),
          ],
          if (selected &&
              addon.hasText &&
              secretMessageText != null &&
              onSecretMsgChanged != null) ...[
            const SizedBox(height: 12),
            _secretMsgInput(),
          ],
        ],
      ),
    );
  }

  Widget _headerRow() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? AppColors.teal.withOpacity(0.15) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(addon.icon, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                addon.label,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textMid,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                addon.description,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        _ToggleSwitch(selected: selected, onTap: onToggle),
      ],
    );
  }

  Widget _colorPickerRow() {
    return Row(
      children: [
        const Text(
          'اللون:',
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: hexToColor(color),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: hexToColor(color).withOpacity(0.4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _colorOptionsRow()),
      ],
    );
  }

  Widget _colorOptionsRow() {
    // sprinkles → fixed 3 colors only
    final hexList = addon.fixedColors
        ? sprinklesFixedColors.map((e) => e.value).toList()
        : addonQuickColors;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: hexList.map((hex) {
          final isCurrent = hex.toLowerCase() == color.toLowerCase();
          return GestureDetector(
            onTap: () => onColorChanged!(hex),
            child: Container(
              width: isCurrent ? 28 : 24,
              height: isCurrent ? 28 : 24,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: hexToColor(hex),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent ? AppColors.primary : Colors.grey[300]!,
                  width: isCurrent ? 2.5 : 1,
                ),
              ),
              child: isCurrent
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: isDarkColor(hexToColor(hex))
                          ? Colors.white
                          : AppColors.primary,
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _secretMsgInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: TextField(
        controller: TextEditingController(text: secretMessageText)
          ..selection = TextSelection.collapsed(offset: secretMessageText!.length),
        onChanged: onSecretMsgChanged,
        maxLength: 60,
        textDirection: TextDirection.rtl,
        style: const TextStyle(color: AppColors.primary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'اكتب الرسالة السرية هنا...',
          hintStyle: const TextStyle(color: AppColors.hint, fontSize: 12),
          filled: true,
          fillColor: Colors.transparent,
          counterStyle: const TextStyle(color: AppColors.hint),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _ToggleSwitch({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 28,
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : Colors.grey[200],
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: selected ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

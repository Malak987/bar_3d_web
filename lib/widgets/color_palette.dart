import 'package:flutter/material.dart';
import '../data/presets.dart';
import '../services/web_helpers.dart';

class ColorPalette extends StatelessWidget {
  const ColorPalette({
    super.key,
    required this.value,
    required this.onSelect,
    this.label,
  });

  final String value;
  final ValueChanged<String> onSelect;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: const TextStyle(
              color: Color(0xFF374151), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...paletteColors.map((c) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: _Dot(
                  hex: c.hex,
                  selected: value.toLowerCase() == c.hex.toLowerCase(),
                  tooltip: c.name,
                  onTap: () => onSelect(c.hex),
                ),
              )),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () async {
                    final picked = await WebHelpers.pickColor(value);
                    if (picked != null) onSelect(picked);
                  },
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF6B7280)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.hex, required this.selected, required this.tooltip, required this.onTap});
  final String hex;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
            border: Border.all(
              color: selected ? const Color(0xFF008080) : Colors.transparent,
              width: selected ? 2.5 : 0,
            ),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: selected ? 8 : 2)],
          ),
          child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
        ),
      ),
    );
  }
}
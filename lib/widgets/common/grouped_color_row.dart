import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/color_utils.dart';
import '../../data/palette_colors.dart';
import 'color_dot.dart';

/// ──────────────────────────────────────────────────────
/// GroupedColorRow
///
/// A two-row picker:
///   • top    → group filters (chips)
///   • bottom → colors inside the active group
/// ──────────────────────────────────────────────────────
class GroupedColorRow extends StatefulWidget {
  final String label;
  final String selectedHex;
  final ValueChanged<String> onSelect;

  const GroupedColorRow({
    super.key,
    required this.label,
    required this.selectedHex,
    required this.onSelect,
  });

  @override
  State<GroupedColorRow> createState() => _GroupedColorRowState();
}

class _GroupedColorRowState extends State<GroupedColorRow> {
  String _activeGroup = colorGroups.first;

  @override
  void initState() {
    super.initState();
    _syncGroupToSelectedHex(widget.selectedHex);
  }

  @override
  void didUpdateWidget(covariant GroupedColorRow old) {
    super.didUpdateWidget(old);
    if (old.selectedHex != widget.selectedHex) {
      _syncGroupToSelectedHex(widget.selectedHex);
    }
  }

  void _syncGroupToSelectedHex(String hex) {
    for (final c in paletteColors) {
      if (c.hex.toLowerCase() == hex.toLowerCase()) {
        if (mounted) setState(() => _activeGroup = c.group);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupColors = getColorsByGroup(_activeGroup);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        const SizedBox(height: 10),
        _groupChipsRow(),
        const SizedBox(height: 10),
        _colorDotsRow(groupColors),
      ],
    );
  }

  Widget _header() {
    return Row(
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: hexToColor(widget.selectedHex),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: hexToColor(widget.selectedHex).withOpacity(0.4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _groupChipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: colorGroups.map((g) {
          final selected = g == _activeGroup;
          return GestureDetector(
            onTap: () => setState(() => _activeGroup = g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                g,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textLight,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _colorDotsRow(List groupColors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: groupColors
            .map(
              (c) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ColorDot(
                  hex: c.hex,
                  name: c.name,
                  selected: widget.selectedHex.toLowerCase() ==
                      c.hex.toLowerCase(),
                  onTap: () => widget.onSelect(c.hex),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

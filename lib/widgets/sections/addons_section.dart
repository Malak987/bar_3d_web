import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/addon_options.dart';
import '../../models/cake_config.dart';
import '../../models/cake_meta.dart';
import '../common/section.dart';
import '../dialogs/addons_overlay.dart';

/// Section 10 — Add-ons (preview + "See all" overlay)
class AddonsSection extends StatelessWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onChanged;

  const AddonsSection({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = config.selectedAddons;

    return Section(
      number: 10,
      title: 'ADD-ONS',
      arabicTitle: 'الإضافات الفاخرة',
      subtitle: 'لمسة نهائية تجعل كيكتك استثنائية',
      trailing: _SeeAllButton(
        onTap: () => showAddonsOverlay(context, config, onChanged),
      ),
      child: Column(
        children: [
          if (selected.isNotEmpty) _SelectedSummary(ids: selected),
          _quickAddonsRow(selected),
        ],
      ),
    );
  }

  Widget _quickAddonsRow(List<String> selected) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: addonOptions.take(6).map((addon) {
          final isSelected = selected.contains(addon.id);
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _AddonCompactCard(
              addon: addon,
              selected: isSelected,
              onTap: () => _toggleAddon(addon),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _toggleAddon(AddonMeta addon) {
    final list = List<String>.from(config.selectedAddons);
    final colors = Map<String, String>.from(config.addonColors);

    if (list.contains(addon.id)) {
      list.remove(addon.id);
      colors.remove(addon.id);
    } else {
      list.add(addon.id);
      if (addon.hasColor) colors[addon.id] = addon.defaultColor;
    }

    // bow / giftRibbon + full placement → fall back to edges
    var placement = config.pipingPlacement;
    if ((list.contains('bow') || list.contains('giftRibbon')) &&
        placement == 'full') {
      placement = 'edges';
    }

    onChanged(config.copyWith(
      selectedAddons: list,
      addonColors: colors,
      pipingPlacement: placement,
    ));
  }
}

// ── private widgets ────────────────────────────────────────

class _SeeAllButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SeeAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.teal.withOpacity(0.5)),
        ),
        child: const Text(
          'See All / عرض الكل',
          style: TextStyle(
            color: AppColors.teal,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SelectedSummary extends StatelessWidget {
  final List<String> ids;
  const _SelectedSummary({required this.ids});

  @override
  Widget build(BuildContext context) {
    final summary = ids.map((id) {
      final a = addonOptions.firstWhere((o) => o.id == id);
      return '${a.icon} ${a.label}';
    }).join('  •  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.teal, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddonCompactCard extends StatelessWidget {
  final AddonMeta addon;
  final bool selected;
  final VoidCallback onTap;

  const _AddonCompactCard({
    required this.addon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal.withOpacity(0.2),
                  border: Border.all(color: AppColors.teal, width: 1.5),
                ),
                child: Center(
                  child: Text(addon.icon,
                      style: const TextStyle(fontSize: 15)),
                ),
              )
            else
              Text(addon.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 5),
            Text(
              addon.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textLight,
                fontSize: 9,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

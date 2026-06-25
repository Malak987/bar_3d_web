import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../data/addon_options.dart';
import '../../models/cake_config.dart';
import '../../models/cake_meta.dart';
import 'addon_full_card.dart';

/// ──────────────────────────────────────────────────────
/// Bottom-sheet overlay listing every add-on
/// ──────────────────────────────────────────────────────
void showAddonsOverlay(
  BuildContext context,
  CakeConfig config,
  ValueChanged<CakeConfig> onChanged,
) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Addons',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (ctx, _, __) => SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: _AddonsFullPage(
              config: config,
              onConfirm: (c) {
                onChanged(c);
                Navigator.of(ctx).pop();
              },
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, a1, _, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

// ── full-page content ─────────────────────────────────────

class _AddonsFullPage extends StatefulWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onConfirm;

  const _AddonsFullPage({
    required this.config,
    required this.onConfirm,
  });

  @override
  State<_AddonsFullPage> createState() => _AddonsFullPageState();
}

class _AddonsFullPageState extends State<_AddonsFullPage> {
  late List<String> _selected;
  late Map<String, String> _colors;
  late String _secretMsg;

  @override
  void initState() {
    super.initState();
    _selected  = List<String>.from(widget.config.selectedAddons);
    _colors    = Map<String, String>.from(widget.config.addonColors);
    _secretMsg = widget.config.secretMessageText;
  }

  void _toggle(String id, AddonMeta addon) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        _colors.remove(id);
      } else {
        _selected.add(id);
        if (addon.hasColor) _colors[id] = addon.defaultColor;
      }
    });
  }

  void _handleConfirm() {
    // bow / giftRibbon + full placement → switch to edges
    var placement = widget.config.pipingPlacement;
    if ((_selected.contains('bow') || _selected.contains('giftRibbon')) &&
        placement == 'full') {
      placement = 'edges';
    }

    widget.onConfirm(widget.config.copyWith(
      selectedAddons: _selected,
      addonColors: _colors,
      secretMessageText: _secretMsg,
      pipingPlacement: placement,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          _Header(count: _selected.length, onClose: () => Navigator.pop(context)),
          Expanded(child: _buildList()),
          _ConfirmButton(
            count: _selected.length,
            onPressed: _handleConfirm,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: addonOptions.length,
      itemBuilder: (_, i) {
        final addon = addonOptions[i];
        final isSel = _selected.contains(addon.id);
        final color = _colors[addon.id] ?? addon.defaultColor;

        return AddonFullCard(
          addon: addon,
          selected: isSel,
          color: color,
          onToggle: () => _toggle(addon.id, addon),
          onColorChanged: addon.hasColor
              ? (hex) => setState(() => _colors[addon.id] = hex)
              : null,
          secretMessageText: addon.hasText ? _secretMsg : null,
          onSecretMsgChanged: addon.hasText
              ? (v) => setState(() => _secretMsg = v)
              : null,
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  final VoidCallback onClose;

  const _Header({required this.count, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🎁', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإضافات',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'اختر الإضافات المناسبة لتورتك',
                style: TextStyle(color: AppColors.textLight, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          if (count > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, size: 20, color: AppColors.textMid),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final int count;
  final VoidCallback onPressed;

  const _ConfirmButton({required this.count, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Text(
            count == 0 ? 'تأكيد بدون إضافات' : 'تأكيد ($count إضافات)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

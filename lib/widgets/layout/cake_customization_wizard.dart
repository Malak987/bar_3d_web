import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/addon_options.dart';
import '../../models/cake_config.dart';
import '../../models/cake_meta.dart';
import '../../services/api_service.dart';
import '../announcement_ticker.dart';
import '../cake_canvas_view.dart';
import '../common/preview_image.dart';
import '../layout/preview_badge.dart';
import '../sections/base_flavor_section.dart';
import '../sections/cake_colors_section.dart';
import '../sections/photo_section.dart';
import '../sections/piping_colors_section.dart';
import '../sections/piping_shapes_section.dart';
import '../sections/piping_style_section.dart';
import '../sections/size_section.dart';
import '../sections/text_section.dart';

class CakeCustomizationWizard extends StatelessWidget {
  final CakeConfig config;
  final CakeCanvasController canvasController;
  final ValueChanged<CakeConfig> onChanged;
  final int step;
  final String? reviewDesignDataUrl;
  final double totalPrice;

  const CakeCustomizationWizard({
    super.key,
    required this.config,
    required this.canvasController,
    required this.onChanged,
    required this.step,
    required this.reviewDesignDataUrl,
    required this.totalPrice,
  });

  static const _steps = <_WizardStepMeta>[
    _WizardStepMeta('Cake Design', 'التصميم', Icons.cake_outlined),
    _WizardStepMeta('Colors & Decoration', 'الألوان', Icons.palette_outlined),
    _WizardStepMeta('Toppings & Extras', 'الإضافات', Icons.auto_awesome),
    _WizardStepMeta('Photo & Message', 'الصورة والنص', Icons.photo_camera_outlined),
    _WizardStepMeta('Review Design', 'المراجعة', Icons.fact_check_outlined),
  ];

  static int get stepsLength => _steps.length;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: AppColors.bg,
        child: Column(
          children: [
            const AnnouncementTicker(
              message: 'هذا الشكل واقعي بنسبة 70% — راجع التصميم النهائي قبل الإضافة للسلة',
              scrollDuration: Duration(seconds: 10),
              repeatInterval: Duration(seconds: 10),
            ),
            _WizardHeader(step: step, totalPrice: totalPrice),
            Expanded(
              child: _WizardResponsiveContent(
                config: config,
                controller: canvasController,
                stepChild: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: _buildStep(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (step) {
      case 0:
        return _StepScroll(
          key: const ValueKey('step-design'),
          children: [
            _PremiumPanel(
              title: 'شكل الكيكة',
              subtitle: 'اختر شكل التصميم الأساسي',
              child: const _ShapeSelection(),
            ),
            const SizedBox(height: 12),
            SizeSection(config: config, onChanged: onChanged),
            const SizedBox(height: 12),
            BaseFlavorSection(config: config, onChanged: onChanged),
            const SizedBox(height: 12),
            PipingStyleSection(config: config, onChanged: onChanged),
          ],
        );
      case 1:
        return _StepScroll(
          key: const ValueKey('step-colors'),
          children: [
            _SelectedColorStrip(config: config),
            const SizedBox(height: 12),
            CakeColorsSection(config: config, onChanged: onChanged),
            const SizedBox(height: 12),
            PipingShapesSection(config: config, onChanged: onChanged),
            const SizedBox(height: 12),
            PipingColorsSection(config: config, onChanged: onChanged),
          ],
        );
      case 2:
        return _StepScroll(
          key: const ValueKey('step-addons'),
          children: [
            _PremiumPanel(
              title: 'Toppings Grid',
              subtitle: 'اختاري أكثر من topping حسب التصميم',
              child: _AddonGrid(config: config, onChanged: onChanged, showExtras: false),
            ),
            const SizedBox(height: 12),
            _PremiumPanel(
              title: 'Extras Grid',
              subtitle: 'إضافات اختيارية بسعر إضافي',
              child: _AddonGrid(config: config, onChanged: onChanged, showExtras: true),
            ),
          ],
        );
      case 3:
        return _StepScroll(
          key: const ValueKey('step-photo-message'),
          children: [
            _OptionalHint(title: 'Cake Photo', text: 'الصورة اختيارية ويمكن تركها بدون رفع.'),
            PhotoSection(config: config, onChanged: onChanged),
            const SizedBox(height: 12),
            _OptionalHint(title: 'Custom Message', text: 'النص اختياري — مثال: Happy Birthday / Congratulations'),
            TextSection(config: config, onChanged: onChanged),
          ],
        );
      default:
        return _ReviewStep(
          key: const ValueKey('step-review'),
          config: config,
          designDataUrl: reviewDesignDataUrl,
          totalPrice: totalPrice,
        );
    }
  }
}

class _WizardStepMeta {
  final String en;
  final String ar;
  final IconData icon;
  const _WizardStepMeta(this.en, this.ar, this.icon);
}

class _WizardHeader extends StatelessWidget {
  final int step;
  final double totalPrice;

  const _WizardHeader({required this.step, required this.totalPrice});

  @override
  Widget build(BuildContext context) {
    final current = CakeCustomizationWizard._steps[step];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(current.icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(current.ar, style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w900)),
                    Text(current.en, style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.teal.withOpacity(0.22)),
                ),
                child: Text('${totalPrice.toStringAsFixed(0)} EGP', style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(CakeCustomizationWizard._steps.length, (i) {
              final active = i <= step;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 6,
                  margin: EdgeInsetsDirectional.only(end: i == CakeCustomizationWizard._steps.length - 1 ? 0 : 6),
                  decoration: BoxDecoration(
                    color: active ? AppColors.teal : AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepScroll extends StatelessWidget {
  final List<Widget> children;

  const _StepScroll({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      children: children,
    );
  }
}

class _WizardResponsiveContent extends StatelessWidget {
  final CakeConfig config;
  final CakeCanvasController controller;
  final Widget stepChild;

  const _WizardResponsiveContent({
    required this.config,
    required this.controller,
    required this.stepChild,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final isDesktop = width >= 980;
        final isTablet = width >= 680 && width < 980;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 7,
                child: _CanvasPreview(
                  config: config,
                  controller: controller,
                  height: height,
                  borderRadius: 0,
                  showDesktopHints: true,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480, minWidth: 380),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    border: BorderDirectional(start: BorderSide(color: AppColors.border.withOpacity(0.8))),
                  ),
                  child: stepChild,
                ),
              ),
            ],
          );
        }

        final previewHeight = isTablet
            ? (height * 0.34).clamp(210.0, 340.0).toDouble()
            : (height < 500 ? 128.0 : (height * 0.30).clamp(150.0, 260.0).toDouble());

        return Column(
          children: [
            _CanvasPreview(
              config: config,
              controller: controller,
              height: previewHeight,
              borderRadius: 0,
            ),
            Expanded(child: stepChild),
          ],
        );
      },
    );
  }
}

class _CanvasPreview extends StatelessWidget {
  final CakeConfig config;
  final CakeCanvasController controller;
  final double height;
  final double borderRadius;
  final bool showDesktopHints;

  const _CanvasPreview({
    required this.config,
    required this.controller,
    required this.height,
    this.borderRadius = 24,
    this.showDesktopHints = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: showDesktopHints ? 34 : 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: CakeCanvasView(config: config, controller: controller)),
              const Positioned(top: 12, right: 12, child: PremiumPreviewBadge()),
              if (showDesktopHints)
                Positioned(
                  left: 18,
                  bottom: 18,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.86),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(
                        'Drag to rotate • Scroll to zoom • Live production preview',
                        style: TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _PremiumPanel({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ShapeSelection extends StatelessWidget {
  const _ShapeSelection();

  @override
  Widget build(BuildContext context) {
    final shapes = ApiService.loadedShapes;
    if (shapes.isEmpty) {
      return const Text('لا توجد أشكال متاحة حالياً', style: TextStyle(color: AppColors.textLight));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(shapes.length, (index) {
        final shape = shapes[index];
        final selected = index == 0;
        final name = (shape['nameAr'] ?? shape['nameEn'] ?? 'Shape').toString();
        final price = (shape['extraPrice'] as num?)?.toDouble() ?? 0;
        return Container(
          width: 142,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(selected ? Icons.check_circle : Icons.cake_outlined, color: selected ? AppColors.teal : AppColors.primary),
              const SizedBox(height: 8),
              Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
              if (price > 0) Text('+${price.toStringAsFixed(0)} EGP', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
            ],
          ),
        );
      }),
    );
  }
}

class _SelectedColorStrip extends StatelessWidget {
  final CakeConfig config;
  const _SelectedColorStrip({required this.config});

  @override
  Widget build(BuildContext context) {
    final colors = config.colors.take(config.gradientColorCount).toList();
    return _PremiumPanel(
      title: 'Selected Colors',
      subtitle: 'الألوان المختارة تظهر مباشرة على التصميم',
      child: Row(
        children: [
          for (var i = 0; i < colors.length; i++)
            Expanded(
              child: Container(
                margin: EdgeInsetsDirectional.only(end: i == colors.length - 1 ? 0 : 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _parseColor(colors[i]),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(i == 0 ? 'Base' : (i == 1 ? 'Top' : 'Decor'), style: const TextStyle(color: AppColors.textLight, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddonGrid extends StatelessWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onChanged;
  final bool showExtras;

  const _AddonGrid({required this.config, required this.onChanged, required this.showExtras});

  @override
  Widget build(BuildContext context) {
    final items = addonOptions.where((a) => ApiService.isExtraId(a.id) == showExtras).toList();
    if (items.isEmpty) return Text(showExtras ? 'لا توجد Extras حالياً' : 'لا توجد Toppings حالياً', style: const TextStyle(color: AppColors.textLight));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final addon = items[index];
        final selected = config.selectedAddons.contains(addon.id);
        return _AddonTile(addon: addon, selected: selected, onTap: () => _toggle(addon));
      },
    );
  }

  void _toggle(AddonMeta addon) {
    final list = List<String>.from(config.selectedAddons);
    final colors = Map<String, String>.from(config.addonColors);
    if (list.contains(addon.id)) {
      list.remove(addon.id);
      colors.remove(addon.id);
    } else {
      list.add(addon.id);
      if (addon.hasColor) colors[addon.id] = addon.defaultColor;
    }
    onChanged(config.copyWith(selectedAddons: list, addonColors: colors));
  }
}

class _AddonTile extends StatelessWidget {
  final AddonMeta addon;
  final bool selected;
  final VoidCallback onTap;

  const _AddonTile({required this.addon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal.withOpacity(0.10) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.teal : AppColors.border, width: selected ? 2 : 1),
          boxShadow: selected ? [AppColors.tealShadow] : [AppColors.cardShadow],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.06),
                  ),
                  child: Center(child: Text(addon.icon, style: const TextStyle(fontSize: 26))),
                ),
                if (selected)
                  const PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: Icon(Icons.check_circle, color: AppColors.teal, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(addon.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12)),
            const SizedBox(height: 4),
            Text(addon.extraPrice > 0 ? '+${addon.extraPrice.toStringAsFixed(0)} EGP' : 'Free', style: const TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _OptionalHint extends StatelessWidget {
  final String title;
  final String text;

  const _OptionalHint({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
                Text(text, style: const TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final CakeConfig config;
  final String? designDataUrl;
  final double totalPrice;

  const _ReviewStep({super.key, required this.config, required this.designDataUrl, required this.totalPrice});

  @override
  Widget build(BuildContext context) {
    final size = ApiService.selectedSize(config);
    final flavor = ApiService.selectedFlavor(config);
    final piping = ApiService.selectedPiping(config);
    final basePrice = ApiService.selectedSizeBasePrice(config);
    final extras = (totalPrice - basePrice).clamp(0, double.infinity).toDouble();
    final selectedAddons = config.selectedAddons.map(ApiService.addonById).whereType<AddonMeta>().toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      children: [
        _PremiumPanel(
          title: 'Design Preview',
          subtitle: 'الصورة النهائية التي سيتم رفعها وحفظها مع الطلب',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: designDataUrl == null || designDataUrl!.isEmpty
                ? Container(height: 230, color: AppColors.bg, child: const Center(child: Icon(Icons.image_not_supported_outlined, color: AppColors.textLight, size: 44)))
                : PreviewImage(data: designDataUrl!, size: 230),
          ),
        ),
        const SizedBox(height: 12),
        _PremiumPanel(
          title: 'Customization Summary',
          subtitle: 'راجعي كل التفاصيل قبل الإضافة للسلة',
          child: Column(
            children: [
              _ReviewRow('Shape', ApiService.loadedShapes.isNotEmpty ? (ApiService.loadedShapes.first['nameAr'] ?? ApiService.loadedShapes.first['nameEn'] ?? '-').toString() : '-'),
              _ReviewRow('Size', size?.label ?? '-'),
              _ReviewRow('Flavor', flavor?.arabicLabel ?? flavor?.label ?? '-'),
              _ReviewRow('Piping', piping?.label ?? '-'),
              _ReviewRow('Colors', config.colors.take(config.gradientColorCount).join(' / ')),
              _ReviewRow('Toppings / Extras', selectedAddons.isEmpty ? 'لا يوجد' : selectedAddons.map((e) => e.label).join(', ')),
              _ReviewRow('Custom Message', config.text.trim().isEmpty ? 'لا يوجد' : config.text.trim()),
              _ReviewRow('Uploaded Photo', config.topImage == null ? 'لا توجد صورة' : 'تم رفع صورة ✓'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PremiumPanel(
          title: 'Price Summary',
          subtitle: 'تحديث مباشر للسعر',
          child: Column(
            children: [
              _ReviewRow('Base Price', '${basePrice.toStringAsFixed(0)} EGP'),
              _ReviewRow('Extras', '${extras.toStringAsFixed(0)} EGP'),
              const Divider(height: 22),
              _ReviewRow('Total', '${totalPrice.toStringAsFixed(0)} EGP', strong: true),
            ],
          ),
        ),
        if (config.topImage != null) ...[
          const SizedBox(height: 12),
          _PremiumPanel(
            title: 'Uploaded Photo',
            subtitle: 'اختياري',
            child: ClipRRect(borderRadius: BorderRadius.circular(14), child: PreviewImage(data: config.topImage!, size: 160)),
          ),
        ],
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _ReviewRow(this.label, this.value, {this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 112, child: Text(label, style: TextStyle(color: strong ? AppColors.primary : AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w800))),
          Expanded(child: Text(value, style: TextStyle(color: strong ? AppColors.teal : AppColors.primary, fontSize: strong ? 16 : 13, fontWeight: strong ? FontWeight.w900 : FontWeight.w700))),
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

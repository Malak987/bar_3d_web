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
    _WizardStepMeta('Size', 'المقاس', Icons.straighten),
    _WizardStepMeta('Base Flavor', 'نكهة القاعدة', Icons.cake_outlined),
    _WizardStepMeta('Cake Colors', 'ألوان الكيكة', Icons.color_lens_outlined),
    _WizardStepMeta('Piping Area', 'مساحة التزيين', Icons.border_outer),
    _WizardStepMeta('Piping Shape', 'شكل التزيين', Icons.stars_outlined),
    _WizardStepMeta('Piping Colors', 'ألوان التزيين', Icons.palette_outlined),
    _WizardStepMeta('Photo or Text', 'الصورة أو النص', Icons.photo_camera_outlined),
    _WizardStepMeta('Addons & Extras', 'الإضافات', Icons.auto_awesome),
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
          key: const ValueKey('step-size'),
          children: [
            _PremiumPanel(
              title: 'شكل الكيكة الأساسي',
              subtitle: 'اختر شكل التصميم العام',
              child: const _ShapeSelection(),
            ),
            const SizedBox(height: 12),
            SizeSection(config: config, onChanged: onChanged),
          ],
        );
      case 1:
        return _StepScroll(
          key: const ValueKey('step-flavor'),
          children: [
            BaseFlavorSection(config: config, onChanged: onChanged),
          ],
        );
      case 2:
        return _StepScroll(
          key: const ValueKey('step-cake-colors'),
          children: [
            _SelectedColorStrip(config: config),
            const SizedBox(height: 12),
            CakeColorsSection(config: config, onChanged: onChanged),
          ],
        );
      case 3:
        return _StepScroll(
          key: const ValueKey('step-piping-style'),
          children: [
            PipingStyleSection(config: config, onChanged: onChanged),
          ],
        );
      case 4:
        return _StepScroll(
          key: const ValueKey('step-piping-shape'),
          children: [
            PipingShapesSection(config: config, onChanged: onChanged),
          ],
        );
      case 5:
        return _StepScroll(
          key: const ValueKey('step-piping-colors'),
          children: [
            PipingColorsSection(config: config, onChanged: onChanged),
          ],
        );
      case 6:
        return _StepScroll(
          key: const ValueKey('step-photo-text'),
          children: [
            _OptionalHint(
              title: 'تعليمات هامة',
              text: 'اختر إما رفع صورة على الكيكة أو كتابة نص مخصص (لا يمكن الجمع بين الاثنين معاً في نفس الوقت).',
            ),
            const SizedBox(height: 8),
            PhotoSection(
              config: config,
              onChanged: (next) {
                var updated = next;
                if (updated.topImage != null) {
                  updated = updated.copyWith(text: '');
                }
                onChanged(updated);
              },
            ),
            const SizedBox(height: 16),
            TextSection(
              config: config,
              onChanged: (next) {
                var updated = next;
                if (updated.text.trim().isNotEmpty) {
                  updated = CakeConfig(
                    gradientColorCount: updated.gradientColorCount,
                    colors: updated.colors,
                    pipingType: updated.pipingType,
                    pipingColor: updated.pipingColor,
                    pipingColorCount: updated.pipingColorCount,
                    pipingColors: updated.pipingColors,
                    pipingPlacement: updated.pipingPlacement,
                    pipingSize: updated.pipingSize,
                    text: updated.text,
                    textColor: updated.textColor,
                    textPosition: updated.textPosition,
                    textSize: updated.textSize,
                    fontStyle: updated.fontStyle,
                    imageScale: updated.imageScale,
                    topImage: null,
                    autoRotate: updated.autoRotate,
                    cakeScale: updated.cakeScale,
                    cakeHeight: updated.cakeHeight,
                    cakeRadius: updated.cakeRadius,
                    plateColor: updated.plateColor,
                    roughness: updated.roughness,
                    metalness: updated.metalness,
                    clearcoat: updated.clearcoat,
                    baseFlavor: updated.baseFlavor,
                    edgeTop: updated.edgeTop,
                    edgeBottom: updated.edgeBottom,
                    selectedAddons: updated.selectedAddons,
                    addonColors: updated.addonColors,
                    secretMessageText: updated.secretMessageText,
                  );
                }
                onChanged(updated);
              },
            ),
          ],
        );
      case 7:
        final hasCandles = config.selectedAddons.contains('candles');
        final hasSecretMessage = config.selectedAddons.contains('secretMessage');
        return _StepScroll(
          key: const ValueKey('step-addons'),
          children: [
            _PremiumPanel(
              title: 'Toppings Grid',
              subtitle: 'اختر أكثر من إضافة (عند اختيار فيونكة أو شريط ومساحة التزيين كاملة، تتحول تلقائياً للحواف)',
              child: _AddonGrid(
                config: config,
                onChanged: (next) {
                  var updated = next;
                  final hasRibbonOrBow = updated.selectedAddons.any((a) =>
                  a.toLowerCase().contains('ribbon') ||
                      a.toLowerCase().contains('bow') ||
                      a == 'giftRibbon' ||
                      a == 'bow');
                  if (hasRibbonOrBow && updated.pipingPlacement == 'full') {
                    updated = updated.copyWith(pipingPlacement: 'edges');
                  }
                  onChanged(updated);
                },
                showExtras: false,
              ),
            ),
            if (hasCandles) ...[
              const SizedBox(height: 12),
              _NumberCandlePicker(
                config: config,
                onChanged: onChanged,
              ),
            ],
            if (hasSecretMessage) ...[
              const SizedBox(height: 12),
              _SecretMessageInput(
                config: config,
                onChanged: onChanged,
              ),
            ],
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
                  margin: EdgeInsetsDirectional.only(end: i == CakeCustomizationWizard._steps.length - 1 ? 0 : 3),
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
        final isTablet = width >= 600 && width < 980;
        final isLargeDesktop = width >= 1400;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: isLargeDesktop ? 8 : 7,
                child: _CanvasPreview(
                  config: config,
                  controller: controller,
                  height: height,
                  borderRadius: 0,
                  showDesktopHints: true,
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLargeDesktop ? 520 : 480,
                  minWidth: 360,
                ),
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

        // ── Mobile & Tablet responsive canvas height ──
        double previewHeight;
        if (isTablet) {
          // Tablet: 38-42% of height — bigger canvas
          previewHeight = (height * 0.40).clamp(240.0, 400.0).toDouble();
        } else {
          // Mobile: scale with screen, bigger minimum
          final screenH = MediaQuery.of(context).size.height;
          if (screenH < 600) {
            // Small phones
            previewHeight = (height * 0.32).clamp(160.0, 220.0).toDouble();
          } else if (screenH < 750) {
            // Medium phones
            previewHeight = (height * 0.36).clamp(200.0, 280.0).toDouble();
          } else {
            // Large phones
            previewHeight = (height * 0.38).clamp(220.0, 320.0).toDouble();
          }
        }

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

/// Number candle picker — choose 1 or 2 digit numbers + gold/silver color
/// Secret message text input — shown when "secretMessage" addon is selected
class _SecretMessageInput extends StatefulWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onChanged;

  const _SecretMessageInput({required this.config, required this.onChanged});

  @override
  State<_SecretMessageInput> createState() => _SecretMessageInputState();
}

class _SecretMessageInputState extends State<_SecretMessageInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.config.secretMessageText);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PremiumPanel(
      title: 'رسالة سرية 💌',
      subtitle: 'اكتب رسالتك السرية وهتتحط جوا الكيكة',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [AppColors.cardShadow],
        ),
        child: TextField(
          controller: _ctrl,
          maxLines: 2,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 14, color: AppColors.primary),
          decoration: const InputDecoration(
            hintText: 'مثال: كل سنة وانت طيب يا حبيبي ❤️',
            hintStyle: TextStyle(fontSize: 13, color: AppColors.hint),
            prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppColors.teal),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (text) {
            widget.onChanged(widget.config.copyWith(secretMessageText: text));
          },
        ),
      ),
    );
  }
}

class _NumberCandlePicker extends StatelessWidget {
  final CakeConfig config;
  final ValueChanged<CakeConfig> onChanged;

  const _NumberCandlePicker({required this.config, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final digits = config.candleDigits;
    final candleColor = config.addonColors['candles'] ?? '#D4A24A';
    final isGold = candleColor.toLowerCase().contains('d4a');

    return _PremiumPanel(
      title: 'شمع أرقام',
      subtitle: 'اختر رقم أو رقمين (0-9) واللون ذهبي أو سيلفر',
      child: Column(
        children: [
          // ── Color selection: Gold / Silver ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CandleColorChip(
                label: 'ذهبي ✨',
                color: const Color(0xFFD4A24A),
                selected: isGold,
                onTap: () {
                  final colors = Map<String, String>.from(config.addonColors);
                  colors['candles'] = '#D4A24A';
                  onChanged(config.copyWith(addonColors: colors));
                },
              ),
              const SizedBox(width: 12),
              _CandleColorChip(
                label: 'سيلفر 🪩',
                color: const Color(0xFFC0C0C0),
                selected: !isGold,
                onTap: () {
                  final colors = Map<String, String>.from(config.addonColors);
                  colors['candles'] = '#C0C0C0';
                  onChanged(config.copyWith(addonColors: colors));
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Digit count selector ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('عدد الأرقام: ', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              _DigitCountBtn(label: 'رقم واحد', selected: digits.length <= 1, onTap: () {
                final d = digits.isNotEmpty ? [digits.first] : <int>[];
                onChanged(config.copyWith(candleDigits: d));
              }),
              const SizedBox(width: 8),
              _DigitCountBtn(label: 'رقمين', selected: digits.length == 2, onTap: () {
                final d = digits.isEmpty
                    ? [0, 0]
                    : digits.length == 1
                    ? [digits.first, 0]
                    : digits.toList();
                onChanged(config.copyWith(candleDigits: d));
              }),
            ],
          ),
          const SizedBox(height: 14),
          // ── Digit pickers ──
          if (digits.isEmpty)
            _DigitGrid(
              label: 'اختر الرقم',
              selectedDigit: null,
              onSelect: (d) => onChanged(config.copyWith(candleDigits: [d])),
            )
          else if (digits.length == 1)
            _DigitGrid(
              label: 'الرقم',
              selectedDigit: digits[0],
              onSelect: (d) => onChanged(config.copyWith(candleDigits: [d])),
            )
          else ...[
              _DigitGrid(
                label: 'الرقم الأول (العشرات)',
                selectedDigit: digits[0],
                onSelect: (d) => onChanged(config.copyWith(candleDigits: [d, digits[1]])),
              ),
              const SizedBox(height: 10),
              _DigitGrid(
                label: 'الرقم الثاني (الآحاد)',
                selectedDigit: digits[1],
                onSelect: (d) => onChanged(config.copyWith(candleDigits: [digits[0], d])),
              ),
            ],
        ],
      ),
    );
  }
}

class _CandleColorChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CandleColorChip({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 2.5 : 1),
          boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)] : [AppColors.cardShadow],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.textLight, fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _DigitCountBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DigitCountBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textMid, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }
}

class _DigitGrid extends StatelessWidget {
  final String label;
  final int? selectedDigit;
  final ValueChanged<int> onSelect;

  const _DigitGrid({required this.label, required this.selectedDigit, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(10, (i) {
            final selected = selectedDigit == i;
            return GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? AppColors.teal : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? AppColors.teal : AppColors.border, width: selected ? 2 : 1),
                  boxShadow: selected ? [AppColors.tealShadow] : [AppColors.cardShadow],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$i',
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
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

    // Build a list of widgets: each addon tile + optional color picker row
    final children = <Widget>[];
    for (final addon in items) {
      final selected = config.selectedAddons.contains(addon.id);
      children.add(
        _AddonTile(
          addon: addon,
          selected: selected,
          currentColor: config.addonColors[addon.id],
          onTap: () => _toggle(addon),
          onColorChanged: addon.hasColor && selected && addon.id != 'candles'
              ? (color) => _changeColor(addon.id, color)
              : null,
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.78,
      children: children,
    );
  }

  void _toggle(AddonMeta addon) {
    final list = List<String>.from(config.selectedAddons);
    final colors = Map<String, String>.from(config.addonColors);
    List<int>? newDigits;

    if (list.contains(addon.id)) {
      list.remove(addon.id);
      colors.remove(addon.id);
      // Clear digits when candles are removed
      if (addon.id == 'candles') newDigits = [];
    } else {
      list.add(addon.id);
      if (addon.hasColor) colors[addon.id] = addon.defaultColor;
      // Set default digit when candles are added
      if (addon.id == 'candles') {
        newDigits = [0];
        colors['candles'] = '#D4A24A'; // Gold by default
      }
    }
    onChanged(config.copyWith(
      selectedAddons: list,
      addonColors: colors,
      candleDigits: newDigits,
    ));
  }

  void _changeColor(String addonId, String color) {
    final colors = Map<String, String>.from(config.addonColors);
    colors[addonId] = color;
    // Only update addonColors — affects 3D shape only
    onChanged(config.copyWith(addonColors: colors));
  }
}

class _AddonTile extends StatelessWidget {
  final AddonMeta addon;
  final bool selected;
  final String? currentColor;
  final VoidCallback onTap;
  final ValueChanged<String>? onColorChanged;

  const _AddonTile({
    required this.addon,
    required this.selected,
    this.currentColor,
    required this.onTap,
    this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final showColorPicker = selected && addon.hasColor && onColorChanged != null;
    final activeColor = currentColor ?? addon.defaultColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal.withOpacity(0.10) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.teal : AppColors.border, width: selected ? 2 : 1),
          boxShadow: selected ? [AppColors.tealShadow] : [AppColors.cardShadow],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.06),
                  ),
                  child: Center(child: Text(addon.icon, style: const TextStyle(fontSize: 22))),
                ),
                if (selected)
                  const PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: Icon(Icons.check_circle, color: AppColors.teal, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(addon.label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 11)),
            const SizedBox(height: 3),
            Text(addon.extraPrice > 0 ? '+${addon.extraPrice.toStringAsFixed(0)} EGP' : 'Free', style: const TextStyle(color: AppColors.orange, fontSize: 10, fontWeight: FontWeight.w800)),
            if (showColorPicker) ...[
              const SizedBox(height: 6),
              _AddonColorPicker(
                addonId: addon.id,
                fixedColors: addon.fixedColors,
                activeColor: activeColor,
                onColorChanged: onColorChanged!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline color picker row for a selected addon — only affects 3D shape
class _AddonColorPicker extends StatelessWidget {
  final String addonId;
  final bool fixedColors;
  final String activeColor;
  final ValueChanged<String> onColorChanged;

  const _AddonColorPicker({
    required this.addonId,
    required this.fixedColors,
    required this.activeColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Use fixed colors for sprinkles, otherwise use the quick color palette
    final colors = (fixedColors || addonId == 'sprinkles')
        ? sprinklesFixedColors.map((e) => e.value).toList()
        : addonQuickColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: colors.map((hex) {
          final isActive = activeColor.toLowerCase() == hex.toLowerCase();
          final color = _parseHex(hex);
          return GestureDetector(
            onTap: () => onColorChanged(hex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: isActive ? 22 : 18,
              height: isActive ? 22 : 18,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppColors.teal : Colors.white,
                  width: isActive ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(isActive ? 0.6 : 0.2),
                    blurRadius: isActive ? 6 : 2,
                  ),
                ],
              ),
              child: isActive
                  ? Icon(Icons.check, size: 10,
                  color: _isDark(color) ? Colors.white : AppColors.primary)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _parseHex(String hex) {
    var v = hex.replaceAll('#', '');
    if (v.length == 6) v = 'FF$v';
    return Color(int.tryParse(v, radix: 16) ?? 0xFFFFFFFF);
  }

  bool _isDark(Color c) =>
      (0.299 * c.red + 0.587 * c.green + 0.114 * c.blue) < 128;
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

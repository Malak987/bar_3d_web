import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../data/addon_options.dart';
import '../data/cake_options.dart';
import '../data/palette_colors.dart';
import '../models/cake_config.dart';
import '../services/access_detector.dart';
import '../services/api_service.dart';
import '../services/auth_guard.dart';
import '../services/session_validator.dart';
import '../services/web_helpers.dart';
import '../widgets/cake_canvas_view.dart';
import '../widgets/layout/cake_customization_wizard.dart';

/// 🎂 Cake Designer Page — Pure designer UI
///
/// This widget is ONLY rendered after:
/// 1. AuthGuard.ensureAuthenticated() has succeeded
/// 2. ApiService.loadCustomization() has completed
/// 3. CakeConfig has been pre-loaded
///
/// The AuthGate layer handles ALL authentication and initialization.
/// This page focuses solely on the design experience.
///
/// Phase 5: The ONLY supported completion flow is CAKE_DESIGN_COMPLETED.
///
/// bar_3d_web owns:
/// • 3D rendering and scene management
/// • Cake customization UI and wizard
/// • Design state management
/// • Preview image generation
/// • Image upload to backend
/// • Exporting final design payload
///
/// bar_web owns:
/// • AddToCart API call
/// • Cart state and persistence
/// • Checkout, orders, payment
///
/// The designer does NOT call AddToCart API. It sends CAKE_DESIGN_COMPLETED
/// and waits for Flutter to handle commerce operations.
class CakeDesignerPage extends StatefulWidget {
  /// Primary constructor — used by DesignerAuthGate
  final CakeConfig preloadedConfig;
  final AuthSession? authSession;
  final AccessClassification? accessClassification;

  /// Backward-compat constructor (for testing only)
  const CakeDesignerPage({
    super.key,
  })  : preloadedConfig = const _DefaultConfig(),
        authSession = null,
        accessClassification = null;

  /// Factory constructor — used by DesignerAuthGate
  const CakeDesignerPage.fromAuthGate({
    super.key,
    required CakeConfig this.preloadedConfig,
    this.authSession,
    this.accessClassification,
  }) : assert(preloadedConfig is! _DefaultConfig);

  @override
  State<CakeDesignerPage> createState() => _CakeDesignerPageState();
}

class _DefaultConfig extends CakeConfig {
  const _DefaultConfig()
      : super(
    cakeRadius: 0.78,
    cakeHeight: 0.42,
    baseFlavor: '',
    colors: const ['#f5efe2', '#fcd5ce', '#ec4f8c'],
    pipingType: 'openStar',
    pipingColor: '#f5efe2',
    pipingColors: const ['#f5efe2'],
    pipingColorCount: 1,
    gradientColorCount: 1,
    selectedAddons: const [],
    addonColors: const {},
    autoRotate: true,
    cakeScale: 1.0,
    // Required CakeConfig parameters
    pipingPlacement: 'border',
    pipingSize: 0.015,
    text: '',
    textColor: '#000000',
    textPosition: 'center',
    textSize: 0.08,
    fontStyle: 'normal',
    imageScale: 1.0,
    topImage: null,
    plateColor: '#f5efe2',
    roughness: 0.5,
    metalness: 0.0,
    clearcoat: 0.8,
    edgeTop: false,
    edgeBottom: false,
    secretMessageText: '',
  );
}

class _CakeDesignerPageState extends State<CakeDesignerPage> {
  final CakeCanvasController _canvasCtrl = CakeCanvasController();
  late CakeConfig _config;
  bool _adding = false;
  int _step = 0;
  String? _reviewDesignDataUrl;

  @override
  void initState() {
    super.initState();
    _config = widget.preloadedConfig;

    // Log access for audit
    WebHelpers.notifyFlutterBridge('LOG_EVENT', {
      'message': 'Designer mounted (auth: ${widget.authSession?.authMethod ?? 'unknown'}, '
          'access: ${AccessDetector.accessDescription})',
    });

    print('[CakeDesignerPage] ✅ Mounted — auth: ${widget.authSession?.authMethod}, '
        'access: ${AccessDetector.accessDescription}');

    // ── Bridge Health Check ──────────────────────────────────────
    // Verify flutter_inappwebview.callHandler is accessible before
    // the user tries to complete a design. This catches the case
    // where hasFlutterBridge returns false (bridge not injected).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBridgeHealth();
    });
  }

  void _checkBridgeHealth() {
    // hasFlutterBridge getter already logs the result
    final bridgeAvailable = WebHelpers.hasFlutterBridge;
    print('[CakeDesignerPage] 🔍 Bridge health check: hasFlutterBridge=$bridgeAvailable');

    if (!bridgeAvailable) {
      print('[CakeDesignerPage] ⚠️ WARNING: Flutter bridge NOT available!');
      print('[CakeDesignerPage] ⚠️ CAKE_DESIGN_COMPLETED will NOT reach Flutter');
      print('[CakeDesignerPage] ⚠️ This is likely why the cart screen does not appear');
      print('[CakeDesignerPage] 💡 CAUSE: window.flutter_inappwebview is null/undefined');
      print('[CakeDesignerPage] 💡 Verify: Is the designer running inside flutter_inappwebview?');
      print('[CakeDesignerPage] 💡 ALTERNATIVE: Check if addJavaScriptHandler in Flutter registered');
      // Notify Flutter about the bridge issue for diagnostics
      WebHelpers.notifyFlutterBridge('LOG_EVENT', {
        'message': 'Bridge health check FAILED: flutter_inappwebview not accessible',
        'accessType': AccessDetector.accessDescription,
      });
    } else {
      print('[CakeDesignerPage] ✅ Bridge health OK — ready for design completion');
      WebHelpers.notifyFlutterBridge('LOG_EVENT', {
        'message': 'Bridge health check PASSED',
        'accessType': AccessDetector.accessDescription,
      });
    }
  }

  void _onCfg(CakeConfig c) {
    var next = c;
    final hasRibbonOrBow = next.selectedAddons.any((a) =>
    a.toLowerCase().contains('ribbon') ||
        a.toLowerCase().contains('bow') ||
        a == 'giftRibbon' ||
        a == 'bow');
    if (hasRibbonOrBow && next.pipingPlacement == 'full') {
      next = next.copyWith(pipingPlacement: 'edges');
    }
    setState(() => _config = next);
  }

  // ── Design Snapshot Capture ─────────────────────────────────────────

  Future<String?> _captureDesignSnapshot({
    int retries = 20,
    bool finalQuality = false,
  }) async {
    for (var i = 0; i < retries; i++) {
      final url = finalQuality
          ? (_canvasCtrl.captureFinalImage() ?? _canvasCtrl.captureScreenshot())
          : (_canvasCtrl.capturePreviewImage() ?? _canvasCtrl.captureScreenshot());
      if (url != null && url.isNotEmpty) return url;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    debugPrint('[CakeDesignerPage] captureDesignSnapshot failed after $retries retries');
    return null;
  }

  // ── Validation ───────────────────────────────────────────────────────

  String? _validationError() {
    if (ApiService.selectedSizeId(_config).isEmpty) {
      return 'من فضلك اختر مقاساً متاحاً';
    }
    if (ApiService.selectedFlavorId(_config).isEmpty) {
      return 'من فضلك اختر نكهة متاحة';
    }
    if (ApiService.selectedShapeId().isEmpty) {
      return 'لا يوجد شكل كيكة متاح حالياً';
    }
    return null;
  }

  // ── Add To Cart Flow ─────────────────────────────────────────────────
  //
  // Phase 5: The ONLY supported flow.
  // 1. Validate design
  // 2. Validate session
  // 3. Capture final design image
  // 4. Upload images to backend
  // 5. Build CAKE_DESIGN_COMPLETED payload
  // 6. Send payload to Flutter via bridge
  // 7. Wait for Flutter to call AddToCart API
  // 8. Show success/failure feedback

  Future<Map<String, dynamic>?> _addToCart() async {
    if (_adding) return null;

    // ── Step 1: Validate design ─────────────────────────
    final validationError = _validationError();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.orange),
      );
      return null;
    }

    // ── Step 2: Validate session ─────────────────────────
    final authCheck = await ApiService.validateSession();
    if (!authCheck.isAuthorized) {
      print('[CakeDesignerPage] 🚫 Session invalid or expired');
      WebHelpers.notifyFlutterBridge('LOG_EVENT', {
        'message': 'AddToCart blocked: session invalid or expired',
      });
      WebHelpers.redirectToLogin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('انتهت صلاحية جلستك — يرجى إعادة فتح المصمم'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return null;
    }

    setState(() => _adding = true);

    // ── Step 3: Capture final design snapshot ─────────────
    final finalDesignDataUrl = await _captureDesignSnapshot(finalQuality: true);
    if (finalDesignDataUrl == null || finalDesignDataUrl.isEmpty) {
      setState(() => _adding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر إنشاء صورة التصميم النهائية'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    // ── Step 4: Upload images to backend ──────────────────
    //
    // bar_3d_web still owns image upload (Three.js renders the preview).
    // These URLs are sent to Flutter in the CAKE_DESIGN_COMPLETED payload.
    final uploaded = await ApiService.uploadImages(
      userPhotoDataUrl: _config.topImage,
      finalDesignDataUrl: finalDesignDataUrl,
    );

    if (uploaded == null || uploaded.designImageUrl.trim().isEmpty) {
      setState(() => _adding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل رفع صورة التصميم'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    // ── Step 5: Build CAKE_DESIGN_COMPLETED payload ────────
    final designId = 'design-${DateTime.now().millisecondsSinceEpoch}';
    final totalPrice = ApiService.calculateTotalPrice(_config);
    final payload = _buildDesignCompletionPayload(
      designId: designId,
      uploadedImages: uploaded,
      totalPrice: totalPrice,
    );

    print('[CakeDesignerPage] 📤 Sending CAKE_DESIGN_COMPLETED: $designId');

    // ── Step 6: Send to Flutter via bridge ─────────────────
    //
    // This is the canonical completion event.
    // Flutter receives the payload and calls AddToCart API.
    // The designer does NOT call AddToCart directly.
    WebHelpers.notifyCakeDesignCompleted(payload);

    setState(() => _adding = false);

    // ── Step 7: Return bridge result ───────────────────────
    //
    // Flutter owns the commerce operation from this point.
    // Designer just shows feedback based on whether Flutter bridge exists.
    return {
      'success': true,
      'designId': designId,
      'finalPrice': totalPrice,
      'totalPrice': totalPrice,
      'event': 'CAKE_DESIGN_COMPLETED',
      'version': 1,
      '_designerVersion': '5.0.0',
    };
  }

  // ── Build CAKE_DESIGN_COMPLETED Payload ─────────────────────────────────
  //
  // This payload contains the complete design configuration.
  // Flutter receives it and calls AddToCart API.
  // Backend is authoritative for all pricing and validation.
  //
  // ✅ FIXED: basePrice is now 0 to avoid double-counting the size price.
  // The size price is correctly included in sizeExtraPrice only.
  // This ensures the total price sent to the backend matches what
  // calculateTotalPrice() computes on the 3D website.

  Map<String, dynamic> _buildDesignCompletionPayload({
    required String designId,
    required UploadedDesignImages uploadedImages,
    required double totalPrice,
  }) {
    final colors = _config.colors;

    // ── Resolve UUIDs from API data ─────────────────────────
    String baseColorId = ApiService.colorUuidFromHex(
      colors.isNotEmpty ? colors[0] : null,
    );
    String topColorId = ApiService.colorUuidFromHex(
      colors.length > 1 ? colors[1] : (colors.isNotEmpty ? colors[0] : null),
    );
    String decorationColorId = ApiService.colorUuidFromHex(
      colors.length > 2 ? colors[2] : null,
    );

    String sizeId = ApiService.selectedSizeId(_config);
    String flavorId = ApiService.selectedFlavorId(_config);
    String shapeId = ApiService.selectedShapeId();
    String pipingId = ApiService.pipingUuid(_config.pipingType);

    if (baseColorId.isEmpty && paletteColors.isNotEmpty) {
      baseColorId = paletteColors.first.id ?? '';
    }
    if (topColorId.isEmpty && paletteColors.isNotEmpty) {
      topColorId = paletteColors.first.id ?? '';
    }
    if (decorationColorId.isEmpty && paletteColors.isNotEmpty) {
      decorationColorId = paletteColors.first.id ?? '';
    }
    if (sizeId.isEmpty && cakeSizes.isNotEmpty) {
      sizeId = cakeSizes.first.id ?? '';
    }
    if (flavorId.isEmpty && baseFlavors.isNotEmpty) {
      flavorId = baseFlavors.first.id;
    }
    if (shapeId.isEmpty && ApiService.loadedShapes.isNotEmpty) {
      shapeId = (ApiService.loadedShapes.first['id'] as String?) ?? '';
    }
    if (pipingId.isEmpty && pipingOptions.isNotEmpty) {
      pipingId = pipingOptions.first.id;
    }

    // ── Build topping selections ────────────────────────────
    final toppingSelections = <Map<String, String>>[];
    for (final id in _config.selectedAddons) {
      if (id.isEmpty) continue;
      if (ApiService.isExtraId(id)) continue; // extras go in extraIds
      final toppingUuid = ApiService.toppingUuid(id);
      if (toppingUuid != null && toppingUuid.isNotEmpty) {
        toppingSelections.add({
          'toppingId': toppingUuid,
          'selectedColor': _config.addonColors[id] ?? '#FFFFFF',
        });
      }
    }

    // ── Build extra IDs ─────────────────────────────────────
    final extraIds = <String>[];
    for (final id in _config.selectedAddons) {
      if (id.isEmpty) continue;
      if (ApiService.isExtraId(id)) {
        final extraUuid = ApiService.toppingUuid(id) ?? id;
        if (extraUuid.isNotEmpty) extraIds.add(extraUuid);
      }
    }

    // ── Build design config map ─────────────────────────────
    //
    // ✅ FIX: basePrice = 0 (not the size price!)
    // Previously, basePrice was set to selectedSizeBasePrice() which returns
    // the SAME value as selectedSize()?.price (used in sizeExtraPrice).
    // This caused the size price to be counted TWICE by the backend:
    //   backend_total = basePrice + sizeExtraPrice + flavorExtra + ...
    //   = sizePrice + sizePrice + extras (WRONG!)
    //
    // Now: basePrice = 0, sizeExtraPrice = size.price (counted once)
    //   backend_total = 0 + sizePrice + extras (CORRECT!)
    final designConfig = {
      'sizeId': sizeId,
      'shapeId': shapeId,
      'baseColorId': baseColorId,
      'topColorId': topColorId,
      'decorationColorId': decorationColorId,
      'pipingId': pipingId,
      'flavorId': flavorId,
      'coverageType': 0,
      'toppingSelections': toppingSelections,
      'extraIds': extraIds,
      'customMessage': _config.text.trim(),
      'note': _config.secretMessageText.trim(),
      // Image URLs (already uploaded by designer)
      'designImageUrl': uploadedImages.designImageUrl,
      'photoUrl': uploadedImages.photoUrl.isNotEmpty ? uploadedImages.photoUrl : null,
      // ✅ Pricing breakdown — FIXED to avoid double-counting
      'basePrice': 0.0, // ← FIXED: was selectedSizeBasePrice(_config) which duplicated size price
      'sizeExtraPrice': ApiService.selectedSize(_config)?.price ?? 0,
      'flavorExtraPrice': ApiService.selectedFlavor(_config)?.extraPrice ?? 0,
      'pipingExtraPrice': ApiService.selectedPiping(_config)?.extraPrice ?? 0,
    };

    // ── Build preview images list ───────────────────────────
    final previewImages = <String>[];
    if (uploadedImages.photoUrl.isNotEmpty) {
      previewImages.add(uploadedImages.photoUrl);
    }
    previewImages.add(uploadedImages.designImageUrl);

    return {
      'event': 'CAKE_DESIGN_COMPLETED',
      'version': 1,
      'designId': designId,
      'design': designConfig,
      'previewImages': previewImages,
      'estimatedPrice': totalPrice,
      'currency': 'EGP',
      'timestamp': DateTime.now().toIso8601String(), // Phase 5: timestamp for audit
      'source': 'web',
      'designerVersion': '5.0.0',
    };
  }

  // ── Wizard Navigation ──────────────────────────────────────────────────

  Future<void> _continueStep() async {
    if (_adding) return;

    if (_step < CakeCustomizationWizard.stepsLength - 1) {
      if (_step == CakeCustomizationWizard.stepsLength - 2) {
        final preview = await _captureDesignSnapshot();
        if (preview == null || preview.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تعذر إنشاء صورة المراجعة'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        setState(() => _reviewDesignDataUrl = preview);
      }
      setState(() => _step++);
      return;
    }

    await _handleAddToCart();
  }

  void _backStep() {
    if (_adding) return;
    if (_step > 0) setState(() => _step--);
  }

  // ── Handle Add To Cart ────────────────────────────────────────────────
  //
  // CAKE_DESIGN_COMPLETED has been sent to Flutter.
  // The designer shows feedback and waits for Flutter's response.
  //
  // If no Flutter bridge exists (standalone browser fallback),
  // show a local success message.

  Future<void> _handleAddToCart() async {
    final result = await _addToCart();
    if (!mounted || result == null) return;

    // لو داخل Flutter mobile WebView:
    // Flutter هيستقبل CAKE_DESIGN_COMPLETED ويعمل navigation.
    if (WebHelpers.hasFlutterBridge) {
      return;
    }

    // لو داخل iframe في Flutter Web:
    // ممنوع نفتح fallback cart جوه iframe.
    // إحنا بعتنا postMessage للـ parent، والـ parent هو اللي هيفتح customize cart.
    if (WebHelpers.isEmbeddedInIframe) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال التصميم للتطبيق، جاري فتح السلة...'),
          backgroundColor: AppColors.teal,
        ),
      );
      return;
    }

    // Standalone browser فقط، يعني المستخدم فاتح bar_3d_web لوحده.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمت إضافة التصميم للسلة بنجاح ✓'),
        backgroundColor: AppColors.teal,
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const _FallbackCartPage()),
    );
  }

  // ── Build UI ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SizedBox.expand(
        child: Column(children: [
          Expanded(
            child: CakeCustomizationWizard(
              config: _config,
              canvasController: _canvasCtrl,
              onChanged: _onCfg,
              step: _step,
              reviewDesignDataUrl: _reviewDesignDataUrl,
              totalPrice: ApiService.calculateTotalPrice(_config),
            ),
          ),
          _WizardActionBar(
            step: _step,
            totalSteps: CakeCustomizationWizard.stepsLength,
            totalPrice: ApiService.calculateTotalPrice(_config),
            adding: _adding,
            onBack: _backStep,
            onContinue: _continueStep,
          ),
        ]),
      ),
    );
  }
}

// ── Action Bar ───────────────────────────────────────────────────────────

class _WizardActionBar extends StatelessWidget {
  final int step;
  final int totalSteps;
  final double totalPrice;
  final bool adding;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _WizardActionBar({
    required this.step,
    required this.totalSteps,
    required this.totalPrice,
    required this.adding,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'السعر الإجمالي',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${totalPrice.toStringAsFixed(0)} EGP',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (step > 0) ...[
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: adding ? null : onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: isLast ? 170 : 150,
            height: 52,
            child: ElevatedButton(
              onPressed: adding ? null : onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? AppColors.orange : AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: adding
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : Text(
                isLast ? 'Add To Cart' : 'Continue',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fallback Cart Page ────────────────────────────────────────────────────
//
// Only shown in standalone browser mode (no Flutter bridge).
// In production, Flutter handles the cart screen.

class _FallbackCartPage extends StatelessWidget {
  const _FallbackCartPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'سلة التصميمات المخصصة',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.teal, size: 68),
            const SizedBox(height: 12),
            const Text(
              'تمت إضافة التصميم بنجاح!',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'الرجوع للتطبيق الرئيسي لإكمال الطلب',
              style: TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
              child: const Text(
                'العودة للرئيسسية',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

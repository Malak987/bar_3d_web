import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../data/presets.dart';
import '../data/addon_options.dart';
import '../data/palette_colors.dart';
import '../models/cake_config.dart';
import '../services/web_helpers.dart';
import '../services/api_service.dart';
import '../features/customization/pages/customization_cart_page.dart';
import '../widgets/cake_canvas_view.dart';
import '../widgets/common/preview_image.dart';
import '../widgets/layout/cake_customization_wizard.dart';

class CakeDesignerPage extends StatefulWidget {
  const CakeDesignerPage({super.key});
  @override
  State<CakeDesignerPage> createState() => _CakeDesignerPageState();
}

class _CakeDesignerPageState extends State<CakeDesignerPage> {
  final CakeCanvasController _canvasCtrl = CakeCanvasController();
  CakeConfig _config = initialCakeConfig;
  bool _loading = true;
  bool _adding = false;
  int _step = 0;
  String? _reviewDesignDataUrl;
  Map<String, dynamic>? _lastAddToCartResult;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    // Bootstrap loads the designer for both entry points:
    // 1) Native app/WebView with AuthTransfer token.
    // 2) Web ecommerce/browser entry where auth may already exist or happen later.
    // Auth is required only when submitting/Add-To-Cart, not for opening preview.
    _bootstrap();
    WebHelpers.onContextUpdated((_) { if (mounted) _bootstrap(); });
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    setState(() { _loading = true; _loadError = null; });

    final authOk = await ApiService.exchangeTransferTokenFromUrl();
    if (!mounted) return;
    if (!authOk) {
      // Do NOT block the configurator. The page must be openable from the
      // mobile app, the ecommerce web app, iframe, and plain browser. If auth
      // is missing, Add-To-Cart will request/validate it and show the proper
      // action message there.
      debugPrint('[CakeDesignerPage] AuthTransfer not available at startup; continuing in design-only mode.');
      WebHelpers.notifyFlutterBridge('LOG_EVENT', {
        'message': 'Designer opened without AuthTransfer; design-only mode until Add-To-Cart',
      });
    }

    final ok = await ApiService.loadCustomization();
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _loading = false;
        _loadError = 'تعذر تحميل اختيارات التخصيص';
      });
      return;
    }
    setState(() {
      _config = ApiService.normalizeConfig(_config);
      _loading = false;
    });
  }

  void _onCfg(CakeConfig c) => setState(() => _config = c);

  Future<String?> _captureDesignSnapshot({int retries = 20, bool finalQuality = false}) async {
    // The Three.js canvas is kept mounted across all wizard steps.
    // Review uses a light preview image; Add-To-Cart uses a final render.
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

  void _download() {
    _captureDesignSnapshot(retries: 3, finalQuality: true).then((url) {
      if (url != null) {
        WebHelpers.downloadDataUrl(
          dataUrl: url,
          fileName: 'cake-${DateTime.now().millisecondsSinceEpoch}.png',
        );
      }
    });
  }

  Map<String, dynamic> _buildCustomizationPayload({
    String? photoUrl,
    required String designImageUrl,
  }) {
    final colors = _config.colors;

    // ✅ ALL color fields must be UUIDs (not hex codes)
    // colorUuidFromHex returns '' if color not found → we must use first available color as fallback
    String baseColorId = ApiService.colorUuidFromHex(
      colors.isNotEmpty ? colors[0] : null,
    );
    String topColorId = ApiService.colorUuidFromHex(
      colors.length > 1 ? colors[1] : (colors.isNotEmpty ? colors[0] : null),
    );
    String decorationColorId = ApiService.colorUuidFromHex(
      colors.length > 2 ? colors[2] : null,
    );

    // 🔧 FALLBACK: If color UUID is empty, use first color from palette
    if (baseColorId.isEmpty && paletteColors.isNotEmpty) {
      baseColorId = paletteColors.first.id ?? '';
      print('[API] ⚠️ baseColorId was empty, using fallback: $baseColorId');
    }
    if (topColorId.isEmpty && paletteColors.isNotEmpty) {
      topColorId = paletteColors.first.id ?? '';
      print('[API] ⚠️ topColorId was empty, using fallback: $topColorId');
    }
    if (decorationColorId.isEmpty && paletteColors.isNotEmpty) {
      decorationColorId = paletteColors.first.id ?? '';
      print('[API] ⚠️ decorationColorId was empty, using fallback: $decorationColorId');
    }

    // Build topping selections with proper UUID mapping
    final toppingSelections = <Map<String, dynamic>>[];
    final extraIds = <String>[];

    for (final id in _config.selectedAddons) {
      if (id.isEmpty) continue;

      if (_isExtra(id)) {
        // ✅ Extra IDs must be UUIDs
        final extraUuid = ApiService.toppingUuid(id) ?? id;
        if (extraUuid.isNotEmpty) {
          extraIds.add(extraUuid);
        }
      } else {
        // ✅ Topping selections must have valid UUID toppingId
        final toppingUuid = ApiService.toppingUuid(id);
        if (toppingUuid != null && toppingUuid.isNotEmpty) {
          toppingSelections.add({
            'toppingId': toppingUuid,
            'selectedColor': _config.addonColors[id] ?? '#FFFFFF',
          });
        }
      }
    }

    // ✅ All required fields must be non-empty UUIDs
    String sizeId = ApiService.selectedSizeId(_config);
    String flavorId = ApiService.selectedFlavorId(_config);
    String shapeId = ApiService.firstShapeId ?? '';
    String pipingId = ApiService.pipingUuid(_config.pipingType);

    // 🔧 FALLBACK: Use first available option if field is empty
    if (sizeId.isEmpty && cakeSizes.isNotEmpty) {
      sizeId = cakeSizes.first.id ?? '';
      print('[API] ⚠️ sizeId was empty, using fallback: $sizeId');
    }
    if (flavorId.isEmpty && baseFlavors.isNotEmpty) {
      flavorId = baseFlavors.first.id;
      print('[API] ⚠️ flavorId was empty, using fallback: $flavorId');
    }
    if (shapeId.isEmpty && ApiService.loadedShapes.isNotEmpty) {
      final firstShape = ApiService.loadedShapes.first;
      shapeId = (firstShape['id'] as String?) ?? '';
      print('[API] ⚠️ shapeId was empty, using fallback: $shapeId');
    }
    if (pipingId.isEmpty && pipingOptions.isNotEmpty) {
      pipingId = pipingOptions.first.id;
      print('[API] ⚠️ pipingId was empty, using fallback: $pipingId');
    }

    // ✅ FINAL VALIDATION: Log ALL fields before sending to catch 500 errors
    print('[API] ════════════ ADD TO CART PAYLOAD ════════════');
    print('[API] sizeId:             "$sizeId" ${sizeId.isEmpty ? "❌ EMPTY" : "✅"}');
    print('[API] baseColorId:        "$baseColorId" ${baseColorId.isEmpty ? "❌ EMPTY" : "✅"}');
    print('[API] topColorId:         "$topColorId" ${topColorId.isEmpty ? "❌ EMPTY" : "✅"}');
    print('[API] decorationColorId:  "$decorationColorId" ${decorationColorId.isEmpty ? "❌ EMPTY" : "✅"}');
    print('[API] shapeId:            "$shapeId" ${shapeId.isEmpty ? "❌ EMPTY" : "✅"}');
    print('[API] pipingId:           "$pipingId" ${pipingId.isEmpty ? "❌ EMPTY" : "✅"}');
    print('[API] flavorId:           "$flavorId" ${flavorId.isEmpty ? "❌ EMPTY" : "✅"}');
    print('[API] coverageType:       0');
    print('[API] toppingSelections:  ${toppingSelections.length} items');
    print('[API] extraIds:           ${extraIds.length} items');
    print('[API] quantity:           1');
    print('[API] customMessage:      "${_config.text}"');
    print('[API] note:               "${_config.secretMessageText}"');
    print('[API] designImageUrl:     "$designImageUrl"');
    print('[API] photoUrl:           "$photoUrl"');
    print('[API] basePrice:          ${ApiService.selectedSizeBasePrice(_config)}');
    print('[API] ════════════════════════════════════════════');

    // 🔴 BUSINESS VALIDATION: required before AddToCart.
    // Photo, custom message, note, toppings, extras, piping and colors are optional.
    final missingRequired = <String>[];
    if (sizeId.isEmpty) missingRequired.add('sizeId');
    if (flavorId.isEmpty) missingRequired.add('flavorId');
    if (shapeId.isEmpty) missingRequired.add('shapeId');
    if (designImageUrl.trim().isEmpty) missingRequired.add('designImageUrl');

    if (missingRequired.isNotEmpty) {
      print('[API] 🚫 BLOCKED: missing required fields: $missingRequired');
      throw Exception('Required fields missing: ${missingRequired.join(', ')}');
    }

    // ✅ Payload must match backend DTO exactly
    // Backend CustomizationCart entity likely needs productId for FK relationship
    // basePrice must be double (backend expects decimal)
    final basePriceDouble = ApiService.selectedSizeBasePrice(_config).toDouble();

    return {
      'sizeId': sizeId,
      'baseColorId': baseColorId,
      'topColorId': topColorId,
      'decorationColorId': decorationColorId,
      'shapeId': shapeId,
      'pipingId': pipingId,
      'flavorId': flavorId,
      'coverageType': 0,
      'toppingSelections': toppingSelections,
      'extraIds': extraIds,
      'quantity': 1,
      'customMessage': _config.text.trim(),
      'note': _config.secretMessageText.trim(),
      'designImageUrl': designImageUrl,
      'photoUrl': (photoUrl ?? '').trim(),
      'basePrice': basePriceDouble,  // ✅ Ensure double, not int
    };
  }

  bool _isExtra(String id) => ApiService.isExtraId(id);

  String? _validationError() {
    if (ApiService.selectedSizeId(_config).isEmpty) return 'من فضلك اختر مقاساً متاحاً';
    if (ApiService.selectedFlavorId(_config).isEmpty) return 'من فضلك اختر نكهة متاحة';
    if (ApiService.selectedShapeId().isEmpty) return 'لا يوجد شكل كيكة متاح حالياً';
    return null;
  }

  Future<Map<String, dynamic>?> _addToCart() async {
    if (_adding) return null;

    final validationError = _validationError();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError), backgroundColor: Colors.orange));
      return null;
    }

    // Ensure auth transfer has completed. The website never receives raw Flutter
    // JWTs; it exchanges the short-lived transfer token itself.
    if (!ApiService.isAuthenticated) {
      final exchanged = await ApiService.exchangeTransferTokenFromUrl();
      if (!exchanged && !ApiService.isAuthenticated) {
        WebHelpers.notifyFlutterBridge('LOG_EVENT', {
          'message': 'AddToCart blocked: AuthTransfer is not authenticated',
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يلزم تسجيل الدخول لإضافة التصميم للسلة. افتح التصميم من التطبيق مع transferToken أو سجل الدخول من الويب ثم حاول مرة أخرى'),
          backgroundColor: Colors.orange,
        ));
        return null;
      }
    }

    // Critical image rule: the final rendered 3D design image is mandatory.
    // The customer photo on cake is optional and may be absent.

    setState(() => _adding = true);

    final finalDesignDataUrl = await _captureDesignSnapshot(finalQuality: true);
    if (finalDesignDataUrl == null || finalDesignDataUrl.isEmpty) {
      setState(() => _adding = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تعذر إنشاء صورة التصميم النهائية'),
        backgroundColor: Colors.red,
      ));
      return null;
    }

    final uploaded = await ApiService.uploadImages(
      userPhotoDataUrl: _config.topImage,
      finalDesignDataUrl: finalDesignDataUrl,
    );

    if (uploaded == null || uploaded.designImageUrl.trim().isEmpty) {
      setState(() => _adding = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('فشل رفع صورة التصميم النهائية'),
        backgroundColor: Colors.red,
      ));
      return null;
    }

    final payload = _buildCustomizationPayload(
      photoUrl: uploaded.photoUrl,
      designImageUrl: uploaded.designImageUrl,
    );
    final addResult = await ApiService.addCustomizationToCart(payload);

    if (!addResult.success) {
      setState(() => _adding = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(addResult.message ?? 'فشل إضافة التصميم للسلة'), backgroundColor: Colors.red));
      return null;
    }

    final finalPrice = ApiService.calculateTotalPrice(_config);
    final bridgeResult = {
      'success': true,
      'cartUpdated': true,
      'designImageUrl': uploaded.designImageUrl,
      'finalDesignImage': uploaded.designImageUrl,
      'photoUrl': uploaded.photoUrl,
      'cartItemId': addResult.cartItemId ?? '',
      'customizationJson': _canvasCtrl.exportCustomizationJSON(),
      'customizationMetadata': _canvasCtrl.exportSelectedOptionsMetadata({
        'finalPrice': finalPrice,
        'designImageUrl': uploaded.designImageUrl,
        'photoUrl': uploaded.photoUrl,
      }),
      'finalPrice': finalPrice,
      // Keep Flutter app legacy handlers happy if they listen to
      // cakeCustomizationResult directly.
      'sizeId': payload['sizeId'],
      'flavorId': payload['flavorId'],
      'shapeId': payload['shapeId'],
      'quantity': payload['quantity'],
      'totalPrice': finalPrice,
    };

    setState(() {
      _adding = false;
      _lastAddToCartResult = bridgeResult;
    });
    return bridgeResult;
  }

  Future<void> _continueStep() async {
    if (_adding) return;
    if (_step < CakeCustomizationWizard.stepsLength - 1) {
      if (_step == 3) {
        final preview = await _captureDesignSnapshot();
        if (preview == null || preview.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تعذر إنشاء صورة مراجعة التصميم'),
              backgroundColor: Colors.red,
            ));
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

  Future<void> _handleAddToCart() async {
    final result = await _addToCart();
    if (!mounted || result == null) return;

    // Notify the host app first. If a native WebView bridge exists, the native
    // app should close the designer and open its own cart screen. If this is a
    // plain web/browser run, navigate to the in-web customization cart.
    _notifyFlutterCartUpdated(result);

    if (!WebHelpers.hasFlutterBridge && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تمت إضافة التصميم للسلة بنجاح ✓'),
        backgroundColor: AppColors.teal,
      ));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomizationCartPage()),
      );
    }
  }

  Future<void> _showSuccessSheet(Map<String, dynamic> result) async {
    final preview = _reviewDesignDataUrl;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSuccessSheet(
        previewDataUrl: preview,
        onGoToCart: () {
          Navigator.of(context).pop();
          _notifyFlutterCartUpdated(result);
        },
        onContinueShopping: () {
          Navigator.of(context).pop();
          setState(() => _step = 0);
        },
      ),
    );
  }

  void _notifyFlutterCartUpdated(Map<String, dynamic>? result) {
    final payload = result ?? _lastAddToCartResult;
    if (payload == null) return;
    // Always emit both new and legacy events. Some native app versions listen
    // to `customizationAdded`, while older ones listen to `cakeCustomizationResult`.
    WebHelpers.notifyCustomizationAdded(payload);
    WebHelpers.notifyCustomizationResult(payload);
    if (!WebHelpers.hasFlutterBridge) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('تمت إضافة التصميم للسلة بنجاح ✓'),
        backgroundColor: AppColors.teal,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SizedBox.expand(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _loadError != null
            ? _ErrorState(message: _loadError!, onRetry: _bootstrap)
            : Column(children: [
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
                const Text('السعر الإجمالي', style: TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w700)),
                Text('${totalPrice.toStringAsFixed(0)} EGP', style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w900)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: adding
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(isLast ? 'Add To Cart' : 'Continue', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSuccessSheet extends StatelessWidget {
  final String? previewDataUrl;
  final VoidCallback onGoToCart;
  final VoidCallback onContinueShopping;

  const _AddSuccessSheet({
    required this.previewDataUrl,
    required this.onGoToCart,
    required this.onContinueShopping,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999))),
            const SizedBox(height: 18),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: AppColors.teal, size: 42),
            ),
            const SizedBox(height: 12),
            const Text('Design Added Successfully', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 14),
            if (previewDataUrl != null && previewDataUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Center(child: PreviewImage(data: previewDataUrl!, size: 170)),
              ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onContinueShopping,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Continue Shopping', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onGoToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Go To Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}

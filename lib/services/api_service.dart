import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

import '../data/cake_options.dart';
import '../data/addon_options.dart';
import '../data/palette_colors.dart';
import '../models/cake_config.dart';
import '../models/cake_meta.dart';
import 'auth_guard.dart';
import 'web_helpers.dart';

class UploadedDesignImages {
  final String photoUrl;
  final String designImageUrl;

  const UploadedDesignImages({
    required this.photoUrl,
    required this.designImageUrl,
  });
}

class CustomizationCartAddResult {
  final bool success;
  final String? message;
  final String? cartItemId;
  final Map<String, dynamic>? raw;

  const CustomizationCartAddResult({
    required this.success,
    this.message,
    this.cartItemId,
    this.raw,
  });

  factory CustomizationCartAddResult.failure([String? message]) {
    return CustomizationCartAddResult(success: false, message: message);
  }

  factory CustomizationCartAddResult.fromResponse(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) {
      return const CustomizationCartAddResult(success: true);
    }

    final data = decoded['data'];
    final dataMap = data is Map<String, dynamic> ? data : null;
    final isSucceeded = decoded.containsKey('isSucceeded')
        ? decoded['isSucceeded'] == true
        : true;

    return CustomizationCartAddResult(
      success: isSucceeded,
      message: (decoded['message'] ?? decoded['error'] ?? dataMap?['message'])
          ?.toString(),
      cartItemId: _firstNonEmptyString([
        decoded['cartItemId'],
        decoded['id'],
        dataMap?['cartItemId'],
        dataMap?['id'],
        dataMap?['customizationCartItemId'],
      ]),
      raw: decoded,
    );
  }

  static String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}

class ApiService {
  static const String baseUrl = 'https://bar-backend.runasp.net';

  static const String _fixedProductId = 'ab22d521-b87c-4249-92d6-8dccc03c4660';

  // ── Token access via AuthGuard ─────────────────────────
  static String? get token => AuthGuard.session?.jwt ?? WebHelpers.readToken();

  // ── Authentication status via AuthGuard ────────────────
  //
  // ✅ Now uses AuthGuard's centralized auth state:
  //   - Checks existing valid session first
  //   - Rejects used/expired transfer tokens (replay protection)
  //   - Validates JWT expiry on every check
  //   - Session state survives page reloads
  static bool get isAuthenticated => AuthGuard.isAuthenticated;

  static String get productId => _fixedProductId;

  static String _t(dynamic v) => (v ?? '').toString().trim();
  static String _hex(dynamic v) {
    var h = _t(v);
    if (h.isEmpty) return '#FFFFFF';
    if (!h.startsWith('#')) h = '#$h';
    return h;
  }

  // ── UUID Mappings ─────────────────────────────
  static final Map<String, String> _toppingJsToUuid = {};
  static final Map<String, String> _pipingJsToUuid = {};
  static final Set<String> _extraUuids = <String>{};

  // ── Shapes cache ──────────────────────────────
  static List<Map<String, dynamic>> _shapes = [];
  static List<Map<String, dynamic>> get loadedShapes => _shapes;
  static String? get firstShapeId =>
      _shapes.isNotEmpty ? _shapes.first['id'] as String? : null;

  // ═══════════════════════════════════════════════
  // AUTH TRANSFER — uses AuthGuard for centralized auth
  // ═══════════════════════════════════════════════

  /// Exchange transfer token using the centralized AuthGuard.
  ///
  /// Delegated to AuthGuard which:
  ///   1. Checks for existing valid session (bypass)
  ///   2. Validates replay protection (tokens marked used)
  ///   3. Exchanges token with backend
  ///   4. Marks token used (prevents replay)
  ///   5. Stores session with expiry
  ///   6. Cleans up URL
  ///
  /// Returns AuthResult with status and session info.
  static Future<AuthResult> ensureAuthenticated() {
    return AuthGuard.ensureAuthenticated();
  }

  /// Validate session after page reload.
  /// Checks stored session expiry and JWT validity.
  static Future<AuthResult> validateSession() {
    return AuthGuard.validateOnReload();
  }

  // ═══════════════════════════════════════════════
  // LOAD CUSTOMIZATION — PUBLIC endpoint, NO token needed
  // ═══════════════════════════════════════════════
  static Future<bool> loadCustomization() async {
    try {
      print('[API] Loading all customization options ...');
      final res = await http.get(
        Uri.parse('$baseUrl/api/ProductCustomization/GetAllCustomizations'),
      );
      if (res.statusCode != 200) {
        print('[API] ❌ Status ${res.statusCode}');
        return false;
      }

      final body = json.decode(res.body);
      if (body['isSucceeded'] != true) {
        print('[API] ❌ isSucceeded=false');
        return false;
      }
      final d = body['data'];

      // ── 1. FLAVORS (id = UUID) ──
      if (d['flavors'] != null && (d['flavors'] as List).isNotEmpty) {
        baseFlavors = (d['flavors'] as List).map((f) => BaseFlavor(
          id: _t(f['id']),
          label: _t(f['nameEn']).isNotEmpty ? _t(f['nameEn']) : _t(f['nameAr']),
          arabicLabel: _t(f['nameAr']).isNotEmpty ? _t(f['nameAr']) : _t(f['nameEn']),
          color: _hex(f['color']),
          icon: _t(f['icon']).isNotEmpty ? _t(f['icon']) : '🍫',
          extraPrice: (f['extraPrice'] ?? 0).toDouble(),
        )).toList();
      }

      // ── 2. SIZES (id = UUID) ──
      if (d['sizes'] != null && (d['sizes'] as List).isNotEmpty) {
        cakeSizes = (d['sizes'] as List).map((s) => CakeSizeOption(
          id: _t(s['id']),
          label: _t(s['nameEn']).isNotEmpty ? _t(s['nameEn']) : _t(s['nameAr']),
          serves: _t(s['serves']),
          radius: _radiusFromSizeValue((s['value'] ?? 10).toDouble()),
          height: _heightFromSizeValue((s['value'] ?? 10).toDouble()),
          price: (s['extraPrice'] ?? 0).toDouble(),
        )).toList();
        cakeSizes.sort((a, b) {
          final numA = double.tryParse(RegExp(r'\d+(\.\d+)?').firstMatch(a.label)?.group(0) ?? '') ?? a.radius * 20;
          final numB = double.tryParse(RegExp(r'\d+(\.\d+)?').firstMatch(b.label)?.group(0) ?? '') ?? b.radius * 20;
          return numA.compareTo(numB);
        });
      }

      // ── 3. COLORS (fully API-driven) ──
      if (d['colors'] != null && (d['colors'] as List).isNotEmpty) {
        final apiColors = d['colors'] as List;
        paletteColors = apiColors.map((c) {
          final hex = _hex(c['hexCode']);
          final name = _t(c['nameAr']).isNotEmpty ? _t(c['nameAr']) : _t(c['nameEn']);
          return PaletteColor(
            id: _t(c['id']),
            name: name,
            hex: hex,
            group: _colorGroup(hex, name),
            extraPrice: (c['extraPrice'] ?? 0).toDouble(),
          );
        }).toList();
        final logicalOrder = [
          'أبيض ومحايد 🤍',
          'وردي وبنفسجي 🌸',
          'أحمر ودافئ ❤️',
          'برتقالي وخوخي 🧡',
          'أصفر وذهبي 💛',
          'أخضر ودرجاته 💚',
          'أزرق وسماوي 💙',
          'بني وشوكولاتة 🍫',
          'أسود ورمادي 🖤'
        ];
        final presentGroups = paletteColors.map((c) => c.group).toSet();
        colorGroups = logicalOrder.where((g) => presentGroups.contains(g)).toList();
        for (final g in presentGroups) {
          if (!colorGroups.contains(g)) colorGroups.add(g);
        }
        paletteColors.sort((a, b) {
          int groupCompare = colorGroups.indexOf(a.group).compareTo(colorGroups.indexOf(b.group));
          if (groupCompare != 0) return groupCompare;
          return _luminance(a.hex).compareTo(_luminance(b.hex));
        });
      }

      // ── 4. PIPINGS (id = nameEn for JS) ──
      _pipingJsToUuid.clear();
      if (d['pipings'] != null && (d['pipings'] as List).isNotEmpty) {
        pipingOptions = (d['pipings'] as List).map((p) {
          final jsId = _t(p['nameEn']);
          _pipingJsToUuid[jsId] = _t(p['id']);
          final rawIcon = _t(p['icon']);
          String resolvedIcon = rawIcon;
          if (rawIcon.isEmpty || rawIcon == '✨' || rawIcon == '✦' || rawIcon == '⭐') {
            final key = '$jsId ${_t(p['nameAr'])}'.toLowerCase();
            if (key.contains('open') || key.contains('مفتوح')) resolvedIcon = '🌟';
            else if (key.contains('closed') || key.contains('مغلق')) resolvedIcon = '💫';
            else if (key.contains('rose') || key.contains('ورد')) resolvedIcon = '🌹';
            else if (key.contains('flower') || key.contains('زهر')) resolvedIcon = '🌸';
            else if (key.contains('leaf') || key.contains('ورق') || key.contains('شجر')) resolvedIcon = '🍃';
            else if (key.contains('shell') || key.contains('صدف')) resolvedIcon = '🐚';
            else if (key.contains('wave') || key.contains('موج')) resolvedIcon = '🌊';
            else if (key.contains('basket') || key.contains('سل')) resolvedIcon = '🧺';
            else if (key.contains('lace') || key.contains('دانتيل') || key.contains('لؤلؤ')) resolvedIcon = '📿';
            else if (key.contains('thread') || key.contains('خيوط')) resolvedIcon = '🧶';
            else if (key.contains('grass') || key.contains('عشب')) resolvedIcon = '🌾';
            else if (key.contains('heart') || key.contains('قلب')) resolvedIcon = '💖';
            else if (key.contains('round') || key.contains('دائر')) resolvedIcon = '⚪';
            else if (key.contains('sphere') || key.contains('كرات')) resolvedIcon = '🔮';
            else resolvedIcon = '🌟';
          }
          return PipingMeta(
            id: jsId.isNotEmpty ? jsId : _t(p['id']),
            label: _t(p['nameAr']).isNotEmpty ? _t(p['nameAr']) : jsId,
            icon: resolvedIcon,
            description: _t(p['descriptionAr']).isNotEmpty ? _t(p['descriptionAr']) : _t(p['descriptionEn']),
            extraPrice: (p['extraPrice'] ?? 0).toDouble(),
          );
        }).toList();
      }

      // ── 5. TOPPINGS (id = nameEn for JS) ──
      _toppingJsToUuid.clear();
      if (d['toppings'] != null && (d['toppings'] as List).isNotEmpty) {
        addonOptions = (d['toppings'] as List).map((t) {
          final jsId = _t(t['nameEn']);
          _toppingJsToUuid[jsId] = _t(t['id']);
          return AddonMeta(
            id: jsId.isNotEmpty ? jsId : _t(t['id']),
            label: _t(t['nameAr']).isNotEmpty ? _t(t['nameAr']) : jsId,
            icon: _t(t['icon']).isNotEmpty ? _t(t['icon']) : '🎂',
            description: jsId, hasColor: t['hasColor'] == true,
            defaultColor: _hex(t['defaultColor']),
            category: _cat(t['category']),
            extraPrice: (t['extraPrice'] ?? 0).toDouble(),
          );
        }).toList();
      }

      // ── 6. EXTRAS ──
      _extraUuids.clear();
      if (d['extras'] != null) {
        for (final e in (d['extras'] as List)) {
          final uuid = _t(e['id']);
          if (uuid.isNotEmpty && !addonOptions.any((a) => a.id == uuid)) {
            _extraUuids.add(uuid);
            addonOptions.add(AddonMeta(
              id: uuid,
              label: _t(e['nameAr']).isNotEmpty ? _t(e['nameAr']) : _t(e['nameEn']),
              icon: _extraIcon(e['extraType']),
              description: _t(e['nameEn']).isNotEmpty ? _t(e['nameEn']) : _t(e['nameAr']),
              hasColor: false,
              defaultColor: '#FFD700',
              category: 'center',
              hasText: (e['extraType'] as num?)?.toInt() == 0,
              extraPrice: (e['extraPrice'] ?? 0).toDouble(),
            ));
          }
        }
      }

      // ── 7. SHAPES ──
      if (d['shapes'] != null) {
        _shapes = (d['shapes'] as List)
            .map((s) => {
          'id': _t(s['id']),
          'nameAr': _t(s['nameAr']),
          'nameEn': _t(s['nameEn']),
          'extraPrice': (s['extraPrice'] ?? 0).toDouble(),
        }).toList();
      }

      print('[API] ✅ ${baseFlavors.length}flv ${cakeSizes.length}sz '
          '${paletteColors.length}col ${pipingOptions.length}pip ${addonOptions.length}add');
      return true;
    } catch (e) {
      print('[API] ❌ $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // UPLOAD IMAGES — required BEFORE CustomizationCart/AddToCart
  // ═══════════════════════════════════════════════
  static Future<UploadedDesignImages?> uploadImages({
    String? userPhotoDataUrl,
    required String finalDesignDataUrl,
  }) async {
    try {
      final form = html.FormData();
      final designBlob = _dataUrlToBlob(finalDesignDataUrl);

      if (userPhotoDataUrl != null && userPhotoDataUrl.trim().isNotEmpty) {
        final photoBlob = _dataUrlToBlob(userPhotoDataUrl);
        form.appendBlob('photoUrl', photoBlob, 'user-photo-${DateTime.now().millisecondsSinceEpoch}.png');
      }

      form.appendBlob('designImageUrl', designBlob, 'final-design-${DateTime.now().millisecondsSinceEpoch}.png');

      final req = html.HttpRequest();
      req.open('POST', '$baseUrl/api/CustomizationOrder/UploadImages');
      final t = token;
      req.withCredentials = t == null || t.isEmpty;
      if (t != null && t.isNotEmpty) req.setRequestHeader('Authorization', 'Bearer $t');

      final completer = Completer<UploadedDesignImages?>();
      req.onLoad.listen((_) {
        if (req.status != 200 && req.status != 201) {
          print('[API] UploadImages error ${req.status}: ${req.responseText}');
          completer.complete(null);
          return;
        }
        final body = _tryDecode(req.responseText ?? '');
        final urls = _extractUploadedUrls(body);
        completer.complete(urls);
      });
      req.onError.listen((_) => completer.complete(null));
      req.send(form);
      return completer.future;
    } catch (e) {
      print('[API] UploadImages ❌ $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════
  // ADD TO CUSTOMIZATION CART — DESIGN ONLY, no checkout/business data
  // ═══════════════════════════════════════════════
  static Future<CustomizationCartAddResult> addCustomizationToCart(Map<String, dynamic> payload) async {
    try {
      print('[API] ═══════════════════════════════════════════');
      print('[API] CustomizationCart/AddToCart — Request Payload:');
      payload.forEach((key, value) {
        final displayValue = value is List
            ? '${value.length} items: $value'
            : value.toString();
        print('[API]   $key = $displayValue');
      });
      final currentToken = token;
      print('[API] Authenticated: ${currentToken != null && currentToken.isNotEmpty}');
      print('[API] Token preview: ${currentToken != null && currentToken.isNotEmpty ? currentToken.substring(0, currentToken.length < 20 ? currentToken.length : 20) + '...' : 'NONE'}');
      print('[API] ═══════════════════════════════════════════');

      // ✅ Validate required UUIDs before sending
      final requiredUuidFields = ['sizeId', 'baseColorId', 'topColorId', 'decorationColorId', 'shapeId', 'pipingId', 'flavorId'];
      for (final field in requiredUuidFields) {
        final val = payload[field]?.toString().trim() ?? '';
        if (val.isEmpty) {
          print('[API] ⚠️ REQUIRED FIELD EMPTY: $field — backend will likely return 500');
        }
      }

      final res = await _sendJson(
        method: 'POST',
        path: '/api/CustomizationCart/AddToCart',
        body: payload,
        authenticated: true,
        withCredentials: token == null || token!.isEmpty,
      );

      print('[API] AddToCart response status: ${res.status}');
      print('[API] AddToCart response body: ${res.body.substring(0, res.body.length > 500 ? 500 : res.body.length)}');

      final decoded = _tryDecode(res.body);
      if (res.status < 200 || res.status >= 300) {
        final msg = decoded is Map<String, dynamic>
            ? (decoded['message'] ?? decoded['error'])?.toString()
            : res.body;
        print('[API] CustomizationCart/AddToCart error ${res.status}: ${res.body}');
        return CustomizationCartAddResult.failure(msg ?? 'فشل إضافة التصميم للسلة');
      }

      return CustomizationCartAddResult.fromResponse(decoded);
    } catch (e) {
      print('[API] CustomizationCart/AddToCart ❌ $e');
      return CustomizationCartAddResult.failure(e.toString());
    }
  }

  static String colorUuidFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return '';
    final normalized = hex.toLowerCase().replaceAll('#', '');
    try {
      return paletteColors
          .firstWhere((c) => c.hex.toLowerCase().replaceAll('#', '') == normalized)
          .id ??
          '';
    } catch (_) {
      return '';
    }
  }

  static String pipingUuid(String? jsId) {
    if (jsId == null || jsId.isEmpty) return '';
    return _pipingJsToUuid[jsId] ?? jsId;
  }

  static String toppingUuid(String? jsId) {
    if (jsId == null || jsId.isEmpty) return '';
    return _toppingJsToUuid[jsId] ?? jsId;
  }

  static double selectedSizeBasePrice(CakeConfig config) {
    try {
      return cakeSizes
          .firstWhere((s) => (s.radius - config.cakeRadius).abs() < 0.05)
          .price;
    } catch (_) {
      return cakeSizes.isNotEmpty ? cakeSizes.first.price : 0;
    }
  }

  static String selectedSizeId(CakeConfig config) {
    try {
      return cakeSizes
          .firstWhere((s) => (s.radius - config.cakeRadius).abs() < 0.05)
          .id ??
          '';
    } catch (_) {
      return cakeSizes.isNotEmpty ? (cakeSizes.first.id ?? '') : '';
    }
  }

  static String selectedFlavorId(CakeConfig config) {
    try {
      final f = baseFlavors.firstWhere((f) => f.id == config.baseFlavor);
      return f.id;
    } catch (_) {
      return baseFlavors.isNotEmpty ? baseFlavors.first.id : '';
    }
  }

  static String selectedShapeId() => firstShapeId ?? '';

  static bool isExtraId(String id) => _extraUuids.contains(id);

  static AddonMeta? addonById(String id) {
    try { return addonOptions.firstWhere((a) => a.id == id); } catch (_) { return null; }
  }

  static PipingMeta? selectedPiping(CakeConfig config) {
    try { return pipingOptions.firstWhere((p) => p.id == config.pipingType); } catch (_) { return null; }
  }

  static BaseFlavor? selectedFlavor(CakeConfig config) {
    try { return baseFlavors.firstWhere((f) => f.id == config.baseFlavor); } catch (_) { return null; }
  }

  static CakeSizeOption? selectedSize(CakeConfig config) {
    try { return cakeSizes.firstWhere((s) => (s.radius - config.cakeRadius).abs() < 0.05); } catch (_) { return cakeSizes.isNotEmpty ? cakeSizes.first : null; }
  }

  static PaletteColor? colorByHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.toLowerCase().replaceAll('#', '');
    try {
      return paletteColors.firstWhere((c) => c.hex.toLowerCase().replaceAll('#', '') == normalized);
    } catch (_) {
      return null;
    }
  }

  static double calculateTotalPrice(CakeConfig config, {double baseProductPrice = 0}) {
    var total = baseProductPrice;
    total += selectedSize(config)?.price ?? 0;
    total += selectedFlavor(config)?.extraPrice ?? 0;
    total += selectedPiping(config)?.extraPrice ?? 0;
    total += ApiService.loadedShapes.isNotEmpty
        ? ((ApiService.loadedShapes.first['extraPrice'] as num?)?.toDouble() ?? 0)
        : 0;
    for (final hex in config.colors.take(config.gradientColorCount)) {
      total += colorByHex(hex)?.extraPrice ?? 0;
    }
    for (final hex in config.pipingColors.take(config.pipingColorCount)) {
      total += colorByHex(hex)?.extraPrice ?? 0;
    }
    for (final id in config.selectedAddons) {
      total += addonById(id)?.extraPrice ?? 0;
    }
    return total;
  }

  static CakeConfig normalizeConfig(CakeConfig current) {
    final colors = paletteColors.isNotEmpty
        ? paletteColors.take(3).map((c) => c.hex).toList()
        : List<String>.from(current.colors);
    while (colors.length < 3) { colors.add('#FFFFFF'); }
    final size = cakeSizes.isNotEmpty ? cakeSizes.first : null;
    return current.copyWith(
      colors: colors,
      pipingColors: colors,
      pipingColor: colors.isNotEmpty ? colors.first : '#FFFFFF',
      baseFlavor: baseFlavors.isNotEmpty ? baseFlavors.first.id : current.baseFlavor,
      pipingType: pipingOptions.isNotEmpty ? pipingOptions.first.id : current.pipingType,
      cakeRadius: size?.radius ?? current.cakeRadius,
      cakeHeight: size?.height ?? current.cakeHeight,
      selectedAddons: const [],
      addonColors: const {},
    );
  }

  static List _idsToUuids(dynamic ids, Map<String, String> map) {
    if (ids == null) return [];
    return (ids as List).map((id) => map[id.toString()] ?? id.toString()).toList();
  }

  static double _radiusFromSizeValue(double value) {
    final clamped = value.clamp(10, 30).toDouble();
    return 0.56 + ((clamped - 10) / 16.0) * 0.46;
  }

  static double _heightFromSizeValue(double value) {
    final clamped = value.clamp(10, 30).toDouble();
    return 0.32 + ((clamped - 10) / 16.0) * 0.22;
  }

  static double _luminance(String hex) {
    final h = hex.replaceAll('#', '').toUpperCase();
    if (h.length < 6) return 1.0;
    final r = (int.tryParse(h.substring(0, 2), radix: 16) ?? 255) / 255.0;
    final g = (int.tryParse(h.substring(2, 4), radix: 16) ?? 255) / 255.0;
    final b = (int.tryParse(h.substring(4, 6), radix: 16) ?? 255) / 255.0;
    return r * 0.299 + g * 0.587 + b * 0.114;
  }

  static String _colorGroup(String hex, [String name = '']) {
    final n = name.toLowerCase();
    if (n.contains('أبيض') || n.contains('white') || n.contains('كريم') || n.contains('cream') || n.contains('فانيل') || n.contains('بيج') || n.contains('عاجي')) return 'أبيض ومحايد 🤍';
    if (n.contains('وردي') || n.contains('بينك') || n.contains('pink') || n.contains('زهر') || n.contains('فوشي')) return 'وردي وبنفسجي 🌸';
    if (n.contains('أحمر') || n.contains('red') || n.contains('عنابي') || n.contains('نبيذ') || n.contains('توت')) return 'أحمر ودافئ ❤️';
    if (n.contains('أزرق') || n.contains('blue') || n.contains('سماوي') || n.contains('كحلي') || n.contains('تيركواز') || n.contains('تركواز')) return 'أزرق وسماوي 💙';
    if (n.contains('أخضر') || n.contains('green') || n.contains('فستقي') || n.contains('نعناع') || n.contains('mint') || n.contains('زيتون')) return 'أخضر ودرجاته 💚';
    if (n.contains('أصفر') || n.contains('yellow') || n.contains('ذهبي') || n.contains('gold') || n.contains('ليمون')) return 'أصفر وذهبي 💛';
    if (n.contains('برتقال') || n.contains('orange') || n.contains('خوخ') || n.contains('peach') || n.contains('مشمش')) return 'برتقالي وخوخي 🧡';
    if (n.contains('بني') || n.contains('brown') || n.contains('شوكولات') || n.contains('قهو') || n.contains('كاكاو') || n.contains('كراميل')) return 'بني وشوكولاتة 🍫';
    if (n.contains('أسود') || n.contains('black') || n.contains('رمادي') || n.contains('gray') || n.contains('فضي')) return 'أسود ورمادي 🖤';

    final h = hex.replaceAll('#', '').toUpperCase();
    if (h.length < 6) return 'أبيض ومحايد 🤍';
    final r = (int.tryParse(h.substring(0, 2), radix: 16) ?? 255) / 255.0;
    final g = (int.tryParse(h.substring(2, 4), radix: 16) ?? 255) / 255.0;
    final b = (int.tryParse(h.substring(4, 6), radix: 16) ?? 255) / 255.0;

    final max = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final min = r < g ? (r < b ? r : b) : (g < b ? g : b);
    final delta = max - min;
    final l = (max + min) / 2.0;

    if (delta < 0.08 || l > 0.90) {
      if (l < 0.20) return 'أسود ورمادي 🖤';
      return 'أبيض ومحايد 🤍';
    }
    if (l < 0.20) return 'أسود ورمادي 🖤';

    double hue = 0;
    if (max == r) {
      hue = ((g - b) / delta) % 6;
    } else if (max == g) {
      hue = (b - r) / delta + 2;
    } else {
      hue = (r - g) / delta + 4;
    }
    hue = (hue * 60) % 360;
    if (hue < 0) hue += 360;

    if (hue >= 335 || hue < 15) {
      if (l > 0.68) return 'وردي وبنفسجي 🌸';
      return 'أحمر ودافئ ❤️';
    }
    if (hue >= 15 && hue < 45) {
      if (l < 0.45) return 'بني وشوكولاتة 🍫';
      return 'برتقالي وخوخي 🧡';
    }
    if (hue >= 45 && hue < 68) return 'أصفر وذهبي 💛';
    if (hue >= 68 && hue < 165) return 'أخضر ودرجاته 💚';
    if (hue >= 165 && hue < 260) return 'أزرق وسماوي 💙';
    return 'وردي وبنفسجي 🌸';
  }

  static String _cat(dynamic c) {
    final s = _t(c).toLowerCase();
    if (s == 'center') return 'center';
    if (s == 'edge' || s == 'border') return 'edge';
    return 'surface';
  }

  static String _extraIcon(dynamic type) {
    switch (type) { case 0: return '💌'; case 1: return '🎁'; case 2: return '🕯️'; default: return '⭐'; }
  }

  static html.Blob _dataUrlToBlob(String dataUrl) {
    final comma = dataUrl.indexOf(',');
    final meta = comma >= 0 ? dataUrl.substring(0, comma) : '';
    final data = comma >= 0 ? dataUrl.substring(comma + 1) : dataUrl;
    final mime = RegExp(r'data:([^;]+)').firstMatch(meta)?.group(1) ?? 'image/png';
    final bytes = base64Decode(data);
    return html.Blob([bytes], mime);
  }

  static UploadedDesignImages? _extractUploadedUrls(dynamic body) {
    final root = body is Map<String, dynamic> ? body : <String, dynamic>{};
    final data = root['data'] is Map<String, dynamic>
        ? root['data'] as Map<String, dynamic>
        : root;
    final photoUrl = _firstString([
      data['photoUrl'],
      data['uploadedPhotoUrl'],
      data['userPhotoUrl'],
      data['photo'],
      root['photoUrl'],
    ]);
    final designImageUrl = _firstString([
      data['designImageUrl'],
      data['finalDesignImageUrl'],
      data['renderedImageUrl'],
      data['designUrl'],
      root['designImageUrl'],
    ]);
    if (designImageUrl == null || designImageUrl.isEmpty) {
      print('[API] UploadImages response did not contain designImageUrl: $body');
      return null;
    }
    return UploadedDesignImages(photoUrl: photoUrl ?? '', designImageUrl: designImageUrl);
  }

  static String? _firstString(List<dynamic> values) {
    for (final v in values) {
      final s = _t(v);
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static dynamic _tryDecode(String text) {
    try { return json.decode(text); } catch (_) { return text; }
  }

  static Future<_ApiRawResponse> _sendJson({
    required String method,
    required String path,
    required Map<String, dynamic> body,
    bool authenticated = false,
    bool withCredentials = false,
  }) async {
    final req = html.HttpRequest();
    req.open(method, '$baseUrl$path');
    req.withCredentials = withCredentials;
    req.setRequestHeader('Content-Type', 'application/json');
    req.setRequestHeader('Accept', 'application/json');
    final t = token;
    if (authenticated && t != null && t.isNotEmpty) {
      req.setRequestHeader('Authorization', 'Bearer $t');
    }
    final completer = Completer<_ApiRawResponse>();
    req.onLoad.listen((_) => completer.complete(_ApiRawResponse(req.status ?? 0, req.responseText ?? '')));
    req.onError.listen((_) => completer.complete(_ApiRawResponse(req.status ?? 0, req.responseText ?? '')));
    req.send(json.encode(body));
    return completer.future;
  }
}

class _ApiRawResponse {
  final int status;
  final String body;
  const _ApiRawResponse(this.status, this.body);
}
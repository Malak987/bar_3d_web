import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../data/cake_options.dart';
import '../data/addon_options.dart';
import '../data/palette_colors.dart';
import '../models/cake_meta.dart';
import 'web_helpers.dart';

/// ⭐ Enhanced API Service for WebView
/// Handles all customization-related API calls
class ApiServiceEnhanced {
  static const String baseUrl = 'https://bar-backend.runasp.net';

  // ★ Fixed product ID for cake customization
  static const String _fixedProductId = 'ab22d521-b87c-4249-92d6-8dccc03c4660';
  static String get productId => _fixedProductId;

  // Token comes from session cookie (backend manages it)
  static String? get token => WebHelpers.readToken();

  // ── Helpers ────────────────────────────────
  static String _t(dynamic v) => (v ?? '').toString().trim();
  static String _hex(dynamic v) {
    var h = _t(v);
    if (h.isEmpty) return '#FFFFFF';
    if (!h.startsWith('#')) h = '#$h';
    return h;
  }

  // ── UUID Mappings ─────────────────────────────
  static final Map _toppingJsToUuid = {};
  static final Map _pipingJsToUuid = {};

  // ── Shapes cache ──────────────────────────────
  static List _shapes = [];
  static List get loadedShapes => _shapes;
  static String? get firstShapeId =>
      _shapes.isNotEmpty ? _shapes.first['id'] as String? : null;

  // ═══════════════════════════════════════════════
  // LOAD CUSTOMIZATION — PUBLIC endpoint, NO token needed
  // ═══════════════════════════════════════════════
  static Future loadCustomization() async {
    try {
      print('[API] Loading customization for $productId ...');
      final res = await http.get(
        Uri.parse('$baseUrl/api/ProductCustomization/GetProductCustomization/$productId'),
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
          label: _t(s['sizeName']).isNotEmpty ? _t(s['sizeName']) : _t(s['nameAr']),
          serves: _t(s['serves']),
          radius: (s['radius'] ?? 0.5).toDouble(),
          height: (s['height'] ?? 0.3).toDouble(),
          price: (s['price'] ?? 0).toDouble(),
        )).toList();
      }

      // ── 3. COLORS — Keep original palette, just add UUIDs ──
      if (d['colors'] != null && (d['colors'] as List).isNotEmpty) {
        final apiColors = d['colors'] as List;
        final Map hexToUuid = {};
        for (final c in apiColors) {
          hexToUuid[_hex(c['hexCode']).toLowerCase()] = _t(c['id']);
        }

        // Update existing palette with UUIDs
        for (int i = 0; i < paletteColors.length; i++) {
          final pc = paletteColors[i];
          final uuid = hexToUuid[pc.hex.toLowerCase()];
          if (uuid != null && uuid.isNotEmpty) {
            paletteColors[i] = PaletteColor(
              id: uuid, name: pc.name, hex: pc.hex,
              group: pc.group, extraPrice: pc.extraPrice,
            );
          }
        }

        // Add new API colors not in palette
        final existingHex = paletteColors.map((c) => c.hex.toLowerCase()).toSet();
        for (final c in apiColors) {
          final hex = _hex(c['hexCode']);
          if (!existingHex.contains(hex.toLowerCase())) {
            paletteColors.add(PaletteColor(
              id: _t(c['id']),
              name: _t(c['nameAr']).isNotEmpty ? _t(c['nameAr']) : _t(c['nameEn']),
              hex: hex, group: 'إضافي',
              extraPrice: (c['extraPrice'] ?? 0).toDouble(),
            ));
          }
        }
        if (paletteColors.any((c) => c.group == 'إضافي') && !colorGroups.contains('إضافي')) {
          colorGroups.add('إضافي');
        }
      }

      // ── 4. PIPINGS (id = nameEn for JS) ──
      _pipingJsToUuid.clear();
      if (d['pipings'] != null && (d['pipings'] as List).isNotEmpty) {
        pipingOptions = (d['pipings'] as List).map((p) {
          final jsId = _t(p['nameEn']);
          _pipingJsToUuid[jsId] = _t(p['id']);
          return PipingMeta(
            id: jsId.isNotEmpty ? jsId : _t(p['id']),
            label: _t(p['nameAr']).isNotEmpty ? _t(p['nameAr']) : jsId,
            icon: _t(p['icon']).isNotEmpty ? _t(p['icon']) : '✦',
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
      if (d['extras'] != null) {
        for (final e in (d['extras'] as List)) {
          final uuid = _t(e['id']);
          if (uuid.isNotEmpty && !addonOptions.any((a) => a.id == uuid)) {
            addonOptions.add(AddonMeta(
              id: uuid, label: _t(e['nameAr']).isNotEmpty ? _t(e['nameAr']) : _t(e['nameEn']),
              icon: _extraIcon(e['extraType']), description: _t(e['nameEn']),
              hasColor: false, defaultColor: '#FFD700', category: 'center',
              extraPrice: (e['extraPrice'] ?? 0).toDouble(),
            ));
          }
        }
      }

      // ── 7. SHAPES ──
      if (d['shapes'] != null) {
        _shapes = (d['shapes'] as List)
            .map((s) => {'id': _t(s['id']), 'nameEn': _t(s['nameEn'])}).toList();
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
  // UPLOAD IMAGES — multipart/form-data
  // Returns: { photoUrl: "...", designImageUrl: "..." }
  // ═══════════════════════════════════════════════
  static Future<Map<String, String>?> uploadImages({
    Uint8List? photoBytes,
    String? designImageDataUrl,
    String? photoFileName,
    String? designImageFileName,
  }) async {
    if (photoBytes == null && designImageDataUrl == null) {
      print('[API] No images to upload');
      return null;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/CustomizationOrder/UploadImages'),
      );

      // Add photo image
      if (photoBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'photoUrl',
          photoBytes,
          filename: photoFileName ?? 'photo_${DateTime.now().millisecondsSinceEpoch}.png',
        ));
      }

      // Add design image from data URL
      if (designImageDataUrl != null) {
        // Convert data URL to bytes
        final base64Data = designImageDataUrl.contains(',')
            ? designImageDataUrl.split(',').last
            : designImageDataUrl;

        final designBytes = base64Decode(base64Data);
        request.files.add(http.MultipartFile.fromBytes(
          'designImageUrl',
          designBytes,
          filename: designImageFileName ?? 'design_${DateTime.now().millisecondsSinceEpoch}.png',
        ));
      }

      print('[API] Uploading images...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['isSucceeded'] == true) {
          final data = body['data'];
          print('[API] ✅ Images uploaded: photoUrl=${data['photoUrl']}, designImageUrl=${data['designImageUrl']}');
          return {
            'photoUrl': data['photoUrl'] ?? '',
            'designImageUrl': data['designImageUrl'] ?? '',
          };
        }
      }

      print('[API] ❌ Image upload failed: ${response.statusCode}');
      return null;
    } catch (e) {
      print('[API] ❌ Image upload error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════
  // ADD TO CUSTOMIZATION CART — Full design payload
  // Uses /api/CustomizationCart/AddToCart
  // ═══════════════════════════════════════════════
  static Future<bool> addToCustomCart(Map payload) async {
    // Check auth first
    final isAuth = await _checkAuth();
    if (!isAuth) {
      print('[API] ❌ User not authenticated - cannot add to cart');
      return false;
    }

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/CustomizationCart/AddToCart'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['isSucceeded'] == true) {
          print('[API] ✅ Added to customization cart');
          return true;
        }
      }

      print('[API] ❌ AddToCart failed: ${res.statusCode} - ${res.body}');
      return false;
    } catch (e) {
      print('[API] ❌ AddToCart error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // GET CUSTOMIZATION CART
  // ═══════════════════════════════════════════════
  static Future<Map?> getCustomizationCart() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/CustomizationCart/GetCart'),
      );

      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
      return null;
    } catch (e) {
      print('[API] ❌ GetCart error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════
  // REMOVE FROM CUSTOMIZATION CART
  // ═══════════════════════════════════════════════
  static Future<bool> removeFromCustomizationCart(String cartItemId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/api/CustomizationCart/RemoveFromCart/$cartItemId'),
      );

      return res.statusCode == 200;
    } catch (e) {
      print('[API] ❌ RemoveFromCart error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════
  static Future<bool> _checkAuth() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/CustomizationCart/GetCart'),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static List _idsToUuids(dynamic ids, Map map) {
    if (ids == null) return [];
    return (ids as List).map((id) => map[id.toString()] ?? id.toString()).toList();
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

  // ═══════════════════════════════════════════════
  // BUILD FULL CUSTOMIZATION CART PAYLOAD
  // Called when user clicks "Add to Cart" in WebView
  // ═══════════════════════════════════════════════
  static Map buildCustomizationPayload({
    required String sizeId,
    required String baseColorId,
    required String topColorId,
    required String decorationColorId,
    required String shapeId,
    required String pipingId,
    required String flavorId,
    required int coverageType,
    required List toppingSelections,
    required List extraIds,
    int quantity = 1,
    String? customMessage,
    String? note,
    String? designImageUrl,
    String? photoUrl,
    double basePrice = 0,
  }) {
    // Convert JS topping IDs to UUIDs
    final toppingIds = toppingSelections.map((t) => t['toppingId'] as String).toList();
    final convertedToppings = toppingIds.map((id) => _toppingJsToUuid[id] ?? id).toList();

    // Build topping selections with UUIDs and colors
    final convertedSelections = toppingSelections.map((t) => {
      'toppingId': _toppingJsToUuid[t['toppingId']] ?? t['toppingId'],
      'selectedColor': t['selectedColor'] ?? '#FFFFFF',
    }).toList();

    // Convert extra IDs to UUIDs
    final convertedExtras = extraIds.map((id) => _toppingJsToUuid[id] ?? id).toList();

    // Convert piping ID to UUID
    final convertedPiping = _pipingJsToUuid[pipingId] ?? pipingId;

    return {
      'sizeId': sizeId,
      'baseColorId': baseColorId,
      'topColorId': topColorId,
      'decorationColorId': decorationColorId,
      'shapeId': shapeId,
      'pipingId': convertedPiping,
      'flavorId': flavorId,
      'coverageType': coverageType,
      'toppingSelections': convertedSelections,
      'extraIds': convertedExtras,
      'quantity': quantity,
      'customMessage': customMessage ?? '',
      'note': note ?? '',
      'designImageUrl': designImageUrl ?? '',
      'photoUrl': photoUrl ?? '',
      'basePrice': basePrice,
    };
  }
}
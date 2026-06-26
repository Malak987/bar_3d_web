/// 🎂 CAKE_DESIGN_COMPLETED — The canonical design completion event
///
/// This event replaces the legacy `customizationAdded` and
/// `cakeCustomizationResult` channels. It is the single source of
/// truth for design completion notifications sent to the Flutter app.
///
/// The event carries the full design payload. Flutter is responsible
/// for:
///   1. Validating schema and supported options
///   2. Uploading preview images (or using designer-provided URLs)
///   3. Calling the AddToCart API
///   4. Updating cart state
///   5. Navigating to the native cart screen
///
/// bar_3d_web owns ONLY: 3D rendering, design state, preview generation.
///
/// bar_web owns: AddToCart, cart state, checkout, orders, pricing.
class DesignCompletionPayload {
  // ── Event Identity ─────────────────────────────────────
  static const String eventType = 'CAKE_DESIGN_COMPLETED';
  static const int version = 1;

  // ── Design Identity ────────────────────────────────────
  final String designId;
  final DateTime completedAt;

  // ── Design Configuration ───────────────────────────────
  final DesignConfig design;

  // ── Images ─────────────────────────────────────────────
  /// Preview image data URLs (base64-encoded PNGs).
  /// May contain 0-2 images:
  ///   [0] — Optional user-uploaded photo
  ///   [1] — Final 3D rendered design (REQUIRED for cart)
  final List<String> previewImages;

  // ── Pricing (estimated — backend is authoritative) ─────
  final double estimatedPrice;
  static const String currency = 'EGP';

  // ── Metadata ───────────────────────────────────────────
  /// Source: 'web' | 'mobile_app'
  final String source;
  /// Full semantic version of the designer
  final String designerVersion;

  const DesignCompletionPayload({
    required this.designId,
    required this.completedAt,
    required this.design,
    this.previewImages = const [],
    required this.estimatedPrice,
    this.source = 'web',
    this.designerVersion = '4.0.0',
  });

  /// Primary constructor — used by CakeDesignerPage
  factory DesignCompletionPayload.fromDesign({
    required String designId,
    required Map<String, dynamic> designMap,
    required List<String> previewImages,
    required double estimatedPrice,
    String source = 'web',
  }) {
    return DesignCompletionPayload(
      designId: designId,
      completedAt: DateTime.now(),
      design: DesignConfig.fromMap(designMap),
      previewImages: previewImages,
      estimatedPrice: estimatedPrice,
      source: source,
    );
  }

  /// Converts to a JSON-serializable map for bridge transmission
  Map<String, dynamic> toBridgeJson() => {
    'event': eventType,
    'version': version,
    'designId': designId,
    'design': design.toBridgeJson(),
    'previewImages': previewImages,
    'estimatedPrice': estimatedPrice,
    'currency': currency,
    'completedAt': completedAt.toIso8601String(),
    'source': source,
    'designerVersion': designerVersion,
  };

  /// Whether a final design image is available for AddToCart
  bool get hasFinalDesignImage =>
      previewImages.isNotEmpty && previewImages.last.isNotEmpty;

  /// Short summary for logging
  String get summary =>
      'CAKE_DESIGN_COMPLETED: $designId, price=$estimatedPrice EGP, '
      'images=${previewImages.length}, design=${design.summary}';
}

/// Represents the complete cake design configuration
class DesignConfig {
  // ── Size ───────────────────────────────────────────────
  final String? sizeId;
  final String? sizeName;
  final String? shapeId;
  final String? shapeName;

  // ── Colors ─────────────────────────────────────────────
  final String? baseColorId;
  final String? baseColorHex;
  final String? topColorId;
  final String? topColorHex;
  final String? decorationColorId;
  final String? decorationColorHex;

  // ── Decorating ─────────────────────────────────────────
  final String? pipingId;
  final String? pipingName;
  final int coverageType;

  // ── Flavor ─────────────────────────────────────────────
  final String? flavorId;
  final String? flavorName;

  // ── Toppings & Extras ──────────────────────────────────
  final List<ToppingConfig> toppingSelections;
  final List<String> extraIds;

  // ── Customization Messages ─────────────────────────────
  final String? customMessage;
  final String? note;
  final String? secretMessage;

  // ── Pricing Components ─────────────────────────────────
  final double basePrice;
  final double sizeExtraPrice;
  final double flavorExtraPrice;
  final double pipingExtraPrice;
  final double toppingExtraPrice;
  final double colorExtraPrice;
  final double extraExtraPrice;

  const DesignConfig({
    this.sizeId,
    this.sizeName,
    this.shapeId,
    this.shapeName,
    this.baseColorId,
    this.baseColorHex,
    this.topColorId,
    this.topColorHex,
    this.decorationColorId,
    this.decorationColorHex,
    this.pipingId,
    this.pipingName,
    this.coverageType = 0,
    this.flavorId,
    this.flavorName,
    this.toppingSelections = const [],
    this.extraIds = const [],
    this.customMessage,
    this.note,
    this.secretMessage,
    this.basePrice = 0,
    this.sizeExtraPrice = 0,
    this.flavorExtraPrice = 0,
    this.pipingExtraPrice = 0,
    this.toppingExtraPrice = 0,
    this.colorExtraPrice = 0,
    this.extraExtraPrice = 0,
  });

  /// Build from CakeConfig map and price breakdown
  factory DesignConfig.fromMap(Map<String, dynamic> map) {
    // Parse toppings
    final toppingList = <ToppingConfig>[];
    final rawToppings = map['toppingSelections'];
    if (rawToppings is List) {
      for (final t in rawToppings) {
        if (t is Map) {
          toppingList.add(ToppingConfig(
            toppingId: t['toppingId'] as String? ?? '',
            toppingName: t['toppingName'] as String? ?? '',
            selectedColor: t['selectedColor'] as String? ?? '#FFFFFF',
          ));
        }
      }
    }

    // Parse extra IDs
    final extraList = <String>[];
    final rawExtras = map['extraIds'];
    if (rawExtras is List) {
      for (final e in rawExtras) {
        final s = e?.toString().trim();
        if (s != null && s.isNotEmpty) extraList.add(s);
      }
    }

    // Parse colors
    final colors = map['colors'];
    final colorList = colors is List
        ? colors.map((c) => c?.toString() ?? '#FFFFFF').toList()
        : <String>[];

    // Parse piping colors
    final pipingColors = map['pipingColors'];
    final pipingColorList = pipingColors is List
        ? pipingColors.map((c) => c?.toString() ?? '#FFFFFF').toList()
        : <String>[];

    return DesignConfig(
      sizeId: map['sizeId'] as String?,
      sizeName: map['sizeName'] as String?,
      shapeId: map['shapeId'] as String?,
      shapeName: map['shapeName'] as String?,
      baseColorId: map['baseColorId'] as String?,
      baseColorHex: colorList.isNotEmpty ? colorList[0] : null,
      topColorId: map['topColorId'] as String?,
      topColorHex: colorList.length > 1 ? colorList[1] : (colorList.isNotEmpty ? colorList[0] : null),
      decorationColorId: map['decorationColorId'] as String?,
      decorationColorHex: colorList.length > 2 ? colorList[2] : null,
      pipingId: map['pipingId'] as String?,
      pipingName: map['pipingName'] as String?,
      coverageType: (map['coverageType'] as num?)?.toInt() ?? 0,
      flavorId: map['flavorId'] as String?,
      flavorName: map['flavorName'] as String?,
      toppingSelections: toppingList,
      extraIds: extraList,
      customMessage: _str(map['customMessage']),
      note: _str(map['note']),
      secretMessage: _str(map['secretMessage']),
      basePrice: (map['basePrice'] as num?)?.toDouble() ?? 0,
      sizeExtraPrice: (map['sizeExtraPrice'] as num?)?.toDouble() ?? 0,
      flavorExtraPrice: (map['flavorExtraPrice'] as num?)?.toDouble() ?? 0,
      pipingExtraPrice: (map['pipingExtraPrice'] as num?)?.toDouble() ?? 0,
      toppingExtraPrice: (map['toppingExtraPrice'] as num?)?.toDouble() ?? 0,
      colorExtraPrice: (map['colorExtraPrice'] as num?)?.toDouble() ?? 0,
      extraExtraPrice: (map['extraExtraPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toBridgeJson() => {
    'sizeId': sizeId ?? '',
    'sizeName': sizeName ?? '',
    'shapeId': shapeId ?? '',
    'shapeName': shapeName ?? '',
    'baseColorId': baseColorId ?? '',
    'baseColorHex': baseColorHex ?? '',
    'topColorId': topColorId ?? '',
    'topColorHex': topColorHex ?? '',
    'decorationColorId': decorationColorId ?? '',
    'decorationColorHex': decorationColorHex ?? '',
    'pipingId': pipingId ?? '',
    'pipingName': pipingName ?? '',
    'coverageType': coverageType,
    'flavorId': flavorId ?? '',
    'flavorName': flavorName ?? '',
    'toppingSelections': toppingSelections.map((t) => t.toBridgeJson()).toList(),
    'extraIds': extraIds,
    'customMessage': customMessage ?? '',
    'note': note ?? '',
    'secretMessage': secretMessage ?? '',
    'basePrice': basePrice,
    'sizeExtraPrice': sizeExtraPrice,
    'flavorExtraPrice': flavorExtraPrice,
    'pipingExtraPrice': pipingExtraPrice,
    'toppingExtraPrice': toppingExtraPrice,
    'colorExtraPrice': colorExtraPrice,
    'extraExtraPrice': extraExtraPrice,
  };

  /// Short description of the design for logging
  String get summary {
    final parts = <String>[];
    if (sizeId?.isNotEmpty == true) parts.add('size=$sizeId');
    if (flavorId?.isNotEmpty == true) parts.add('flavor=$flavorId');
    if (shapeId?.isNotEmpty == true) parts.add('shape=$shapeId');
    if (toppingSelections.isNotEmpty) parts.add('toppings=${toppingSelections.length}');
    if (extraIds.isNotEmpty) parts.add('extras=${extraIds.length}');
    return parts.isEmpty ? 'empty' : parts.join(', ');
  }
}

/// Represents a topping selection within the design
class ToppingConfig {
  final String toppingId;
  final String toppingName;
  final String selectedColor;

  const ToppingConfig({
    required this.toppingId,
    this.toppingName = '',
    this.selectedColor = '#FFFFFF',
  });

  Map<String, dynamic> toBridgeJson() => {
    'toppingId': toppingId,
    'toppingName': toppingName,
    'selectedColor': selectedColor,
  };
}

// ── Helpers ─────────────────────────────────────────────────────────────

String? _str(dynamic v) {
  final s = v?.toString().trim();
  return s == null || s.isEmpty ? null : s;
}
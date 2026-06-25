/// 🎂 Enhanced Cake Designer Payload
///
/// Sent from WebView to Flutter via JS Bridge when user completes design
/// Contains full customization data plus image URLs
class CakeDesignerPayload {
  // ── Basic Info ───────────────────────────────
  final String productId;
  final String? productSizeId;
  final List flavorIds;
  final int quantity;
  final String? note;
  final String? customMessage;

  // ── Customization Design Data ─────────────────
  final String? sizeId;
  final String? shapeId;
  final String? baseColorId;
  final String? topColorId;
  final String? decorationColorId;
  final String? pipingId;
  final String? flavorId;
  final int coverageType;

  // ── Toppings & Extras ─────────────────────────
  final List toppingSelections;
  final List extraIds;

  // ── Images (REQUIRED) ─────────────────────────
  final String? photoUrl;          // User uploaded images
  final String? designImageUrl;    // Final rendered cake design image

  // ── Pricing ───────────────────────────────────
  final double basePrice;

  // ── Metadata ──────────────────────────────────
  final String? sizeName;
  final String? productName;
  final Map? extraConfig;

  const CakeDesignerPayload({
    required this.productId,
    this.productSizeId,
    this.flavorIds = const [],
    this.quantity = 1,
    this.note,
    this.customMessage,
    this.sizeId,
    this.shapeId,
    this.baseColorId,
    this.topColorId,
    this.decorationColorId,
    this.pipingId,
    this.flavorId,
    this.coverageType = 0,
    this.toppingSelections = const [],
    this.extraIds = const [],
    this.photoUrl,
    this.designImageUrl,
    this.basePrice = 0,
    this.sizeName,
    this.productName,
    this.extraConfig,
  });

  factory CakeDesignerPayload.fromJson(Map json) {
    return CakeDesignerPayload(
      productId: json['productId'] as String? ?? '',
      productSizeId: json['productSizeId'] as String?,
      flavorIds: (json['flavorIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      note: json['note'] as String?,
      customMessage: json['customMessage'] as String?,
      sizeId: json['sizeId'] as String?,
      shapeId: json['shapeId'] as String?,
      baseColorId: json['baseColorId'] as String?,
      topColorId: json['topColorId'] as String?,
      decorationColorId: json['decorationColorId'] as String?,
      pipingId: json['pipingId'] as String?,
      flavorId: json['flavorId'] as String?,
      coverageType: (json['coverageType'] as num?)?.toInt() ?? 0,
      toppingSelections: (json['toppingSelections'] as List?) ?? [],
      extraIds: (json['extraIds'] as List?) ?? [],
      photoUrl: json['photoUrl'] as String?,
      designImageUrl: json['designImageUrl'] as String?,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      sizeName: json['sizeName'] as String?,
      productName: json['productName'] as String?,
      extraConfig: json['extraConfig'] as Map?,
    );
  }

  Map toJson() => {
    'productId': productId,
    'productSizeId': productSizeId,
    'flavorIds': flavorIds,
    'quantity': quantity,
    'note': note,
    'customMessage': customMessage,
    'sizeId': sizeId,
    'shapeId': shapeId,
    'baseColorId': baseColorId,
    'topColorId': topColorId,
    'decorationColorId': decorationColorId,
    'pipingId': pipingId,
    'flavorId': flavorId,
    'coverageType': coverageType,
    'toppingSelections': toppingSelections,
    'extraIds': extraIds,
    'photoUrl': photoUrl,
    'designImageUrl': designImageUrl,
    'basePrice': basePrice,
    'sizeName': sizeName,
    'productName': productName,
    'extraConfig': extraConfig,
  };

  /// Converts to Flutter's AddToCustomCartRequest format
  Map toAddToCustomCartRequest() => {
    'sizeId': sizeId ?? '',
    'baseColorId': baseColorId ?? '',
    'topColorId': topColorId ?? '',
    'decorationColorId': decorationColorId ?? '',
    'shapeId': shapeId ?? '',
    'pipingId': pipingId ?? '',
    'flavorId': flavorId ?? '',
    'coverageType': coverageType,
    'toppingSelections': toppingSelections,
    'extraIds': extraIds,
    'quantity': quantity,
    'customMessage': customMessage ?? '',
    'note': note ?? '',
    'designImageUrl': designImageUrl ?? '',
    'photoUrl': photoUrl ?? '',
    'basePrice': basePrice,
  };

  @override
  String toString() => 'CakeDesignerPayload(productId: $productId, '
      'sizeId: $sizeId, flavorId: $flavorId, '
      'photoUrl: $photoUrl, designImageUrl: $designImageUrl)';
}

/// Topping Selection with color
class ToppingSelection {
  final String toppingId;
  final String selectedColor;

  const ToppingSelection({
    required this.toppingId,
    required this.selectedColor,
  });

  Map toJson() => {
    'toppingId': toppingId,
    'selectedColor': selectedColor,
  };

  factory ToppingSelection.fromJson(Map json) => ToppingSelection(
    toppingId: json['toppingId'] as String? ?? '',
    selectedColor: json['selectedColor'] as String? ?? '#FFFFFF',
  );
}
/// ──────────────────────────────────────────────────────
/// CakeConfig — Immutable cake-design state
/// ──────────────────────────────────────────────────────
class CakeConfig {
  // Cake body
  final int gradientColorCount;
  final List<String> colors;

  // Piping
  final String pipingType;
  final String pipingColor;
  final int pipingColorCount;
  final List<String> pipingColors;
  final String pipingPlacement; // border | full | edges
  final double pipingSize;

  // Text
  final String text;
  final String textColor;
  final String textPosition; // top | center | bottom
  final double textSize;
  final String fontStyle; // normal | amiri | cursive

  // Image
  final double imageScale;
  final String? topImage;

  // View
  final bool autoRotate;
  final double cakeScale;
  final double cakeHeight;
  final double cakeRadius;

  // Material
  final String plateColor;
  final double roughness;
  final double metalness;
  final double clearcoat;

  // Flavor
  final String baseFlavor; // chocolate | vanilla | mix

  // Edge piping flags (legacy)
  final bool edgeTop;
  final bool edgeBottom;

  // Add-ons
  final List<String> selectedAddons;
  final Map<String, String> addonColors;
  final String secretMessageText;

  // Number candles (0-9, max 2 digits)
  final List<int> candleDigits;

  const CakeConfig({
    required this.gradientColorCount,
    required this.colors,
    required this.pipingType,
    required this.pipingColor,
    required this.pipingColorCount,
    required this.pipingColors,
    required this.pipingPlacement,
    required this.pipingSize,
    required this.text,
    required this.textColor,
    required this.textPosition,
    required this.textSize,
    required this.fontStyle,
    required this.imageScale,
    required this.topImage,
    required this.autoRotate,
    required this.cakeScale,
    required this.cakeHeight,
    required this.cakeRadius,
    required this.plateColor,
    required this.roughness,
    required this.metalness,
    required this.clearcoat,
    required this.baseFlavor,
    required this.edgeTop,
    required this.edgeBottom,
    required this.selectedAddons,
    required this.addonColors,
    required this.secretMessageText,
    this.candleDigits = const [],
  });

  static const Object _sentinel = Object();

  CakeConfig copyWith({
    int? gradientColorCount,
    List<String>? colors,
    String? pipingType,
    String? pipingColor,
    int? pipingColorCount,
    List<String>? pipingColors,
    String? pipingPlacement,
    double? pipingSize,
    String? text,
    String? textColor,
    String? textPosition,
    double? textSize,
    String? fontStyle,
    double? imageScale,
    Object? topImage = _sentinel,
    bool? autoRotate,
    double? cakeScale,
    double? cakeHeight,
    double? cakeRadius,
    String? plateColor,
    double? roughness,
    double? metalness,
    double? clearcoat,
    String? baseFlavor,
    bool? edgeTop,
    bool? edgeBottom,
    List<String>? selectedAddons,
    Map<String, String>? addonColors,
    String? secretMessageText,
    List<int>? candleDigits,
  }) {
    return CakeConfig(
      gradientColorCount: gradientColorCount ?? this.gradientColorCount,
      colors: colors ?? this.colors,
      pipingType: pipingType ?? this.pipingType,
      pipingColor: pipingColor ?? this.pipingColor,
      pipingColorCount: pipingColorCount ?? this.pipingColorCount,
      pipingColors: pipingColors ?? this.pipingColors,
      pipingPlacement: pipingPlacement ?? this.pipingPlacement,
      pipingSize: pipingSize ?? this.pipingSize,
      text: text ?? this.text,
      textColor: textColor ?? this.textColor,
      textPosition: textPosition ?? this.textPosition,
      textSize: textSize ?? this.textSize,
      fontStyle: fontStyle ?? this.fontStyle,
      imageScale: imageScale ?? this.imageScale,
      topImage: identical(topImage, _sentinel)
          ? this.topImage
          : topImage as String?,
      autoRotate: autoRotate ?? this.autoRotate,
      cakeScale: cakeScale ?? this.cakeScale,
      cakeHeight: cakeHeight ?? this.cakeHeight,
      cakeRadius: cakeRadius ?? this.cakeRadius,
      plateColor: plateColor ?? this.plateColor,
      roughness: roughness ?? this.roughness,
      metalness: metalness ?? this.metalness,
      clearcoat: clearcoat ?? this.clearcoat,
      baseFlavor: baseFlavor ?? this.baseFlavor,
      edgeTop: edgeTop ?? this.edgeTop,
      edgeBottom: edgeBottom ?? this.edgeBottom,
      selectedAddons: selectedAddons ?? this.selectedAddons,
      addonColors: addonColors ?? this.addonColors,
      secretMessageText: secretMessageText ?? this.secretMessageText,
      candleDigits: candleDigits ?? this.candleDigits,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CakeConfig &&
            gradientColorCount == other.gradientColorCount &&
            _listEquals(colors, other.colors) &&
            pipingType == other.pipingType &&
            pipingColor == other.pipingColor &&
            pipingColorCount == other.pipingColorCount &&
            _listEquals(pipingColors, other.pipingColors) &&
            pipingPlacement == other.pipingPlacement &&
            pipingSize == other.pipingSize &&
            text == other.text &&
            textColor == other.textColor &&
            textPosition == other.textPosition &&
            textSize == other.textSize &&
            fontStyle == other.fontStyle &&
            imageScale == other.imageScale &&
            topImage == other.topImage &&
            autoRotate == other.autoRotate &&
            cakeScale == other.cakeScale &&
            cakeHeight == other.cakeHeight &&
            cakeRadius == other.cakeRadius &&
            plateColor == other.plateColor &&
            roughness == other.roughness &&
            metalness == other.metalness &&
            clearcoat == other.clearcoat &&
            baseFlavor == other.baseFlavor &&
            edgeTop == other.edgeTop &&
            edgeBottom == other.edgeBottom &&
            _listEquals(selectedAddons, other.selectedAddons) &&
            _mapEquals(addonColors, other.addonColors) &&
            secretMessageText == other.secretMessageText &&
            _listEquals(candleDigits, other.candleDigits);
  }

  @override
  int get hashCode => Object.hashAll([
    gradientColorCount,
    Object.hashAll(colors),
    pipingType,
    pipingColor,
    pipingColorCount,
    Object.hashAll(pipingColors),
    pipingPlacement,
    pipingSize,
    text,
    textColor,
    textPosition,
    textSize,
    fontStyle,
    imageScale,
    topImage,
    autoRotate,
    cakeScale,
    cakeHeight,
    cakeRadius,
    plateColor,
    roughness,
    metalness,
    clearcoat,
    baseFlavor,
    edgeTop,
    edgeBottom,
    Object.hashAll(selectedAddons),
    Object.hashAll(addonColors.entries.map((e) => Object.hash(e.key, e.value))),
    secretMessageText,
    Object.hashAll(candleDigits),
  ]);

  Map<String, dynamic> toJson() => {
    'gradientColorCount': gradientColorCount,
    'colors': colors,
    'pipingType': pipingType,
    'pipingColor': pipingColor,
    'pipingColorCount': pipingColorCount,
    'pipingColors': pipingColors,
    'pipingPlacement': pipingPlacement,
    'pipingSize': pipingSize,
    'text': text,
    'textColor': textColor,
    'textPosition': textPosition,
    'textSize': textSize,
    'fontStyle': fontStyle,
    'imageScale': imageScale,
    'topImage': topImage,
    'autoRotate': autoRotate,
    'cakeScale': cakeScale,
    'cakeHeight': cakeHeight,
    'cakeRadius': cakeRadius,
    'plateColor': plateColor,
    'roughness': roughness,
    'metalness': metalness,
    'clearcoat': clearcoat,
    'baseFlavor': baseFlavor,
    'edgeTop': edgeTop,
    'edgeBottom': edgeBottom,
    'selectedAddons': selectedAddons,
    'addonColors': addonColors,
    'secretMessageText': secretMessageText,
    'candleDigits': candleDigits,
  };
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) return false;
  }
  return true;
}

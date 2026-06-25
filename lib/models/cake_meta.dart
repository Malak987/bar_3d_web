/// ──────────────────────────────────────────────────────
/// Metadata models used by presets & UI
/// ──────────────────────────────────────────────────────

class PaletteColor {
  final String name;
  final String hex;
  final String group;
  final String? id;
  final double extraPrice;

  const PaletteColor({
    required this.name,
    required this.hex,
    this.group = '',
    this.id,
    this.extraPrice = 0.0,
  });
}

class PipingMeta {
  final String id;
  final String label;
  final String icon;
  final String description;
  final double extraPrice;

  const PipingMeta({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
    this.extraPrice = 0.0,
  });
}

class CakeSizeOption {
  final String? id;
  final String label;
  final String serves;
  final double radius;
  final double height;
  final double price;

  const CakeSizeOption({
    this.id,
    required this.label,
    required this.serves,
    required this.radius,
    required this.height,
    this.price = 0.0,
  });
}

class BaseFlavor {
  final String id;
  final String label;
  final String arabicLabel;
  final String color;
  final String icon;
  final double extraPrice;

  const BaseFlavor({
    required this.id,
    required this.label,
    required this.arabicLabel,
    required this.color,
    required this.icon,
    this.extraPrice = 0.0,
  });
}

class AddonMeta {
  final String id;
  final String label;
  final String icon;
  final String description;
  final bool hasColor;
  final String defaultColor;
  final String category; // center | edge | surface
  final bool hasText;
  final bool fixedColors;
  final double extraPrice;

  const AddonMeta({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
    required this.hasColor,
    required this.defaultColor,
    this.category = 'edge',
    this.hasText = false,
    this.fixedColors = false,
    this.extraPrice = 0.0,
  });
}

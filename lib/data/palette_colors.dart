import '../models/cake_meta.dart';

/// Colors are loaded dynamically from:
/// GET /api/ProductCustomization/GetAllCustomizations
List<PaletteColor> paletteColors = [];
List<String> colorGroups = [];

List<PaletteColor> getColorsByGroup(String group) =>
    paletteColors.where((c) => c.group == group).toList();

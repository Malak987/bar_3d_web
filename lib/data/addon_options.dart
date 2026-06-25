import '../models/cake_meta.dart';

/// Toppings and extras are loaded dynamically from:
/// GET /api/ProductCustomization/GetAllCustomizations
///
/// Keep business options empty here. ApiService.loadCustomization()
/// fills this list at runtime from the backend.
List<AddonMeta> addonOptions = [];

/// UI-only color helpers for add-on color pickers.
/// These are not customization items; selected add-on IDs/prices still come
/// from the backend.
const List<MapEntry<String, String>> sprinklesFixedColors = [
  MapEntry('أبيض', '#FFFFFF'),
  MapEntry('جولد', '#D4A24A'),
  MapEntry('سيلفر', '#B0BEC5'),
];

const List<String> addonQuickColors = [
  '#FF6B6B', '#FF80AB', '#CE93D8', '#90CAF9',
  '#80CBC4', '#A5D6A7', '#FFF176', '#FFB74D',
  '#FFFFFF', '#F5EFE2', '#D4A24A', '#3D1A0A',
];

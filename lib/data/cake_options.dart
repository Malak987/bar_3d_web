import '../models/cake_meta.dart';

/// Customization options are loaded dynamically from:
/// GET /api/ProductCustomization/GetAllCustomizations
/// Keep these lists empty at startup to avoid hardcoded business data.
List<BaseFlavor> baseFlavors = [];
List<PipingMeta> pipingOptions = [];
List<CakeSizeOption> cakeSizes = [];

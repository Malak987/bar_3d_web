/// Debug Configuration — FOR DEVELOPMENT ONLY
///
/// Set enabled=true + paste your JWT token to test in Chrome
/// without the Flutter app (flutter run -d chrome).
///
/// ⚠️ Set enabled=false before firebase deploy!
class DebugConfig {
  DebugConfig._();

  static const bool enabled = false;
  static const String token = '';
  static const String productId = 'ab22d521-b87c-4249-92d6-8dccc03c4660';

  // ── Phase 4/5: Commerce Ownership Migration ──────────────────────────
  //
  // ✅ Phase 4 verified — migration is now the ONLY supported flow.
  // bar_3d_web sends CAKE_DESIGN_COMPLETED to Flutter.
  // bar_web calls AddToCart API.
  // Legacy AddToCart path has been removed.
  //
  // Phase 5: Only CAKE_DESIGN_COMPLETED is supported.
  // customizationAdded and cakeCustomizationResult channels are DEPRECATED.
  static const bool commerceOwnershipMigration = true;
}

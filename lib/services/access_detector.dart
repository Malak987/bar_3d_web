// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// 🔐 Access Detector — Determines how the designer was opened
///
/// Critical for access control. The designer must detect:
///
/// ALLOWED ACCESS:
/// 1. BAR Mobile App WebView — `flutter_inappwebview` bridge exists
/// 2. BAR Web Application iframe — parent window is BAR domain
/// 3. Authenticated session already exists — bypass all checks
///
/// FORBIDDEN ACCESS:
/// - Direct browser URL opened without session or transfer token
///
/// Detection strategy:
/// - WebView: `window.flutter_inappwebview` exists
/// - iframe: Check `window.parent` origin against BAR domains
/// - Session: Check localStorage for valid session
/// - Token: Check URL for transfer token
class AccessDetector {
  AccessDetector._();

  // ── WebView Detection ─────────────────────────────────

  /// True if running inside `flutter_inappwebview` (mobile app WebView).
  /// This is an ALLOWED access path.
  static bool get isWebView {
    try {
      // flutter_inappwebview injects this object when running in the app WebView
      final win = html.window as dynamic;
      return win.flutter_inappwebview != null;
    } catch (_) {
      return false;
    }
  }

  // ── iframe Detection ──────────────────────────────────

  /// True if running inside an iframe (has a parent window).
  /// Parent origin is checked against known BAR domains.
  static bool get isEmbeddedInBarApp {
    try {
      if (!isInIframe) return false;
      final parentOrigin = _getParentOrigin();
      if (parentOrigin == null) return false;
      return _isAllowedBarOrigin(parentOrigin);
    } catch (_) {
      return false;
    }
  }

  /// True if the page is running inside an iframe
  static bool get isInIframe {
    try {
      // top is the topmost window; if we're in an iframe, top != current window
      final win = html.window as dynamic;
      final top = win.top;
      return top != html.window;
    } catch (_) {
      return false;
    }
  }

  /// Returns the origin of the parent window if accessible
  static String? _getParentOrigin() {
    try {
      final parent = html.window.parent;
      if (parent == null) return null;
      final parentAsDyn = parent as dynamic;
      final location = parentAsDyn.location;
      if (location == null) return null;
      final locAsDyn = location as dynamic;
      final protocol = locAsDyn.protocol as String? ?? '';
      final host = locAsDyn.host as String? ?? '';
      if (host.isEmpty) return null;
      return '$protocol//$host';
    } catch (_) {
      // Cross-origin iframe — parent is inaccessible (CORS)
      // In this case, we can't verify the origin but we know we're in an iframe
      // We'll rely on session/auth check instead
      return null;
    }
  }

  // ── Access Classification ──────────────────────────────

  /// Complete access classification for the current environment.
  static AccessClassification get classification {
    // Case 1: Mobile app WebView — always allowed
    if (isWebView) {
      return AccessClassification(
        accessType: AccessType.mobileAppWebView,
        isAllowed: true,
        reason: 'Running inside BAR Mobile App WebView (flutter_inappwebview detected)',
      );
    }

    // Case 2: Embedded in BAR web app (iframe) — parent is accessible
    final parentOrigin = _getParentOrigin();
    if (isInIframe && parentOrigin != null && _isAllowedBarOrigin(parentOrigin)) {
      return AccessClassification(
        accessType: AccessType.barWebEmbed,
        isAllowed: true,
        reason: 'Running inside BAR Web Application iframe (origin: $parentOrigin)',
      );
    }

    // Case 3: Cross-origin iframe (parent inaccessible)
    if (isInIframe && parentOrigin == null) {
      // Could be BAR web app in a cross-origin iframe, or unknown
      // The auth check will determine if access is allowed
      return AccessClassification(
        accessType: AccessType.unknownCrossOrigin,
        isAllowed: null,
        reason: 'Running in cross-origin iframe — auth check required',
      );
    }

    // Case 4: Standalone browser — needs auth check
    return AccessClassification(
      accessType: AccessType.standaloneBrowser,
      isAllowed: null,
      reason: 'Running as standalone browser — auth check required',
    );
  }

  /// Returns the access type as a string for audit logging
  static String get accessTypeString {
    return classification.accessType.name;
  }

  /// Human-readable description of access type
  static String get accessDescription {
    final c = classification;
    switch (c.accessType) {
      case AccessType.mobileAppWebView:
        return 'Mobile App WebView';
      case AccessType.barWebEmbed:
        return 'BAR Web Application';
      case AccessType.standaloneBrowser:
        return 'Direct Browser Access';
      case AccessType.unknownCrossOrigin:
        return 'Embedded (cross-origin)';
      case AccessType.unknown:
        return 'Unknown';
    }
  }

  // ── Helpers ────────────────────────────────────────────

  /// Known BAR application origins (for iframe validation)
  static const Set<String> _allowedOrigins = {
    'https://bar-ecommerce.web.app',
    'https://bar-ecommerce.firebaseapp.com',
    'https://bar-app.web.app',
    'https://bar-app.firebaseapp.com',
    'https://www.bar-cake.com',
    'https://bar-cake.web.app',
    // Production domains
    'https://bar-web-xxx.firebaseapp.com',
    // Local development
    'http://localhost:3000',
    'http://localhost:8080',
    'http://localhost:5000',
  };

  static bool _isAllowedBarOrigin(String origin) {
    if (origin.isEmpty) return false;
    // Strip trailing slash
    final clean = origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;
    final withoutProtocol = clean.replaceFirst(RegExp(r'^https?://'), '');

    return _allowedOrigins.any((allowed) {
      final cleanAllowed = allowed.endsWith('/')
          ? allowed.substring(0, allowed.length - 1)
          : allowed;
      final allowedHost = cleanAllowed.replaceFirst(RegExp(r'^https?://'), '');
      // Exact match or subdomain match
      return withoutProtocol == allowedHost ||
          withoutProtocol.endsWith('.$allowedHost');
    });
  }
}

// ── Access Classification Model ────────────────────────────────────────

enum AccessType {
  mobileAppWebView,
  barWebEmbed,
  standaloneBrowser,
  unknownCrossOrigin,
  unknown,
}

class AccessClassification {
  final AccessType accessType;
  final bool? isAllowed; // null = depends on auth state
  final String reason;

  const AccessClassification({
    required this.accessType,
    required this.isAllowed,
    required this.reason,
  });

  /// True if this is a known allowed access path (no additional checks needed)
  bool get isAllowedPath => isAllowed == true;

  /// True if auth check is required to determine access
  bool get needsAuthCheck => isAllowed == null;

  /// True if this access path is forbidden
  bool get isForbidden => isAllowed == false;

  @override
  String toString() =>
      'AccessClassification(type: $accessType, allowed: $isAllowed, reason: $reason)';
}
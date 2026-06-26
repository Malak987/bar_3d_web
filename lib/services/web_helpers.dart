// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'debug_config.dart';

class WebHelpers {
  WebHelpers._();

  // ── Flutter Bridge ────────────────────────────

  static bool get hasFlutterBridge {
    try {
      // flutter_inappwebview injects this object when running in mobile app WebView
      final win = html.window as dynamic;
      final bridge = win.flutter_inappwebview;
      final result = bridge != null;
      print('[WebHelpers] hasFlutterBridge check: window.flutter_inappwebview = $bridge → $result');
      return result;
    } catch (e) {
      print('[WebHelpers] hasFlutterBridge check FAILED: $e');
      return false;
    }
  }

  static void notifyFlutterBridge(String type, Map<String, dynamic> payload) {
    try {
      if (hasFlutterBridge) {
        final win = html.window as dynamic;
        print('[WebHelpers] FlutterBridge → type: $type, payload keys: ${payload.keys.toList()}');
        win.flutter_inappwebview.callHandler('FlutterBridge', {
          'type': type,
          'payload': payload,
        });
      } else {
        print('[WebHelpers] FlutterBridge: hasFlutterBridge=false, skipping $type');
      }
    } catch (e) {
      print('[BAR] FlutterBridge error: $e');
    }
  }

  // ── Bridge Channel Names ────────────────────────────────────────────
  static const String channelCakeDesignCompleted = 'CAKE_DESIGN_COMPLETED';
  static const String channelFlutterBridge = 'FlutterBridge';

  // ── CAKE_DESIGN_COMPLETED — Phase 5 canonical completion event ──────
  //
  // The ONLY supported completion event. bar_3d_web generates the design
  // payload and sends it to Flutter. Flutter owns AddToCart from this point.
  //
  // Payload structure:
  //   event: 'CAKE_DESIGN_COMPLETED'
  //   version: 1
  //   designId: UUID
  //   design: { sizeId, shapeId, flavorId, colors, toppings, extras, ... }
  //   previewImages: [base64 data URLs]
  //   estimatedPrice: number
  //   currency: 'EGP'
  //   timestamp: ISO8601
  //
  // ⚠️  UploadImages and AddToCart are Flutter's responsibility.
  // ⚠️  Legacy channels (customizationAdded, cakeCustomizationResult)
  //     have been removed. Only CAKE_DESIGN_COMPLETED is supported.
  static void notifyCakeDesignCompleted(Map<String, dynamic> payload) {
    try {
      print('[WebHelpers] 📤 Emitting CAKE_DESIGN_COMPLETED: ${payload['designId']}');
      print('[WebHelpers] hasFlutterBridge = $hasFlutterBridge');
      print('[WebHelpers] channel = $channelCakeDesignCompleted');
      print('[WebHelpers] designImageUrl preview: ${payload['design']?['designImageUrl']?.toString().substring(0, (payload['design']?['designImageUrl']?.toString().length ?? 0).clamp(0, 50)) ?? 'MISSING'}...');

      if (hasFlutterBridge) {
        print('[WebHelpers] ✅ Calling flutter_inappwebview.callHandler...');
        final win = html.window as dynamic;
        final result = win.flutter_inappwebview.callHandler(channelCakeDesignCompleted, payload);
        print('[WebHelpers] ✅ callHandler returned: $result');
      } else {
        print('[WebHelpers] ❌ hasFlutterBridge is FALSE — Flutter will NOT receive CAKE_DESIGN_COMPLETED');
        print('[WebHelpers] ❌ This is the root cause! flutter_inappwebview not accessible');
        print('[WebHelpers] 💡 Possible causes:');
        print('[WebHelpers]   1. WebView not running inside flutter_inappwebview (standalone browser)');
        print('[WebHelpers]   2. flutter_inappwebview JavaScript bridge not injected');
        print('[WebHelpers]   3. window.flutter_inappwebview is undefined or null');
        // Check what's actually on window
        print('[WebHelpers] 🔍 Checking window.flutter_inappwebview: ${html.window as dynamic}');
      }

      // postMessage for iframe parents (bar_web iframe / Flutter Web)
      final message = {
        'source': 'bar3dcake',
        'type': channelCakeDesignCompleted,
        'payload': payload,
      };
      _postMessageStrict(message);
      if (html.window.parent != null && html.window.parent != html.window) {
        _postMessageToParent(message);
      }
    } catch (e) {
      print('[WebHelpers] ❌ CAKE_DESIGN_COMPLETED bridge error: $e');
    }
  }

  /// 🔐 postMessage with origin awareness
  /// Phase 6 will add strict origin validation here.
  /// Currently sends to known BAR domains only.
  static void _postMessageStrict(Map<String, dynamic> message) {
    // Phase 6: Validate origin before sending
    // For now, send with specific target origin
    try {
      html.window.postMessage(message, 'https://bar-ecommerce.web.app');
    } catch (_) {
      // Fallback to '*' if specific origin fails
      try {
        html.window.postMessage(message, '*');
      } catch (_) {}
    }
  }

  static void _postMessageToParent(Map<String, dynamic> message) {
    try {
      html.window.parent!.postMessage(message, '*');
    } catch (e) {
      print('[BAR] Parent postMessage error: $e');
    }
  }

  // ── URL query helpers ─────────────────────────

  static String? readQueryParam(String key) {
    try {
      // First, try html.window.location directly for reliability
      final search = html.window.location.search;
      if (search != null && search.isNotEmpty) {
        final params = search.startsWith('?') ? search.substring(1) : search;
        for (final param in params.split('&')) {
          final parts = param.split('=');
          if (parts.length == 2 && parts[0] == key) {
            final value = Uri.decodeComponent(parts[1].trim());
            if (value.isNotEmpty) {
              print('[WebHelpers] 📌 Found param "$key" in location.search: ${value.substring(0, value.length > 8 ? 8 : value.length)}...');
              return value;
            }
          }
        }
      }

      // Fallback to Uri.base
      final uriResult = _getUriParam(Uri.base, key);
      if (uriResult != null) return uriResult;

      // Fallback to parsing location.href
      final currentUrl = html.window.location.href;
      return _getUriParam(Uri.parse(currentUrl), key);
    } catch (e) {
      print('[WebHelpers] ❌ Error reading query param "$key": $e');
      return null;
    }
  }

  static String? _getUriParam(Uri uri, String key) {
    final direct = uri.queryParameters[key];
    if (direct != null && direct.trim().isNotEmpty) {
      return Uri.decodeComponent(direct.trim());
    }
    return null;
  }

  static String? readFirstQueryParam(List<String> keys) {
    print('[WebHelpers] ════════════════════════════════════════════════');
    print('[WebHelpers] 🔍 Looking for token in keys: $keys');
    print('[WebHelpers] 🔍 location.search: "${html.window.location.search}"');
    print('[WebHelpers] 🔍 location.href: "${html.window.location.href}"');

    for (final key in keys) {
      final value = readQueryParam(key);
      if (value != null && value.isNotEmpty) {
        print('[WebHelpers] ✅ Found token for key "$key"');
        print('[WebHelpers] ════════════════════════════════════════════════');
        return value;
      }
    }
    print('[WebHelpers] ❌ No token found in URL query params');
    print('[WebHelpers] 💡 Ensure the URL contains ?token=<value> parameter');
    print('[WebHelpers] ════════════════════════════════════════════════');
    return null;
  }

  /// Remove query params from URL using history.replaceState
  /// This ensures the token disappears from browser history.
  static void removeQueryParam(String key) {
    try {
      final uri = Uri.parse(html.window.location.href);
      var changed = false;
      final params = Map<String, String>.from(uri.queryParameters);
      if (params.remove(key) != null) changed = true;

      var fragment = uri.fragment;
      final qIndex = fragment.indexOf('?');
      if (qIndex >= 0 && qIndex < fragment.length - 1) {
        final prefix = fragment.substring(0, qIndex);
        final fragParams = Uri.splitQueryString(fragment.substring(qIndex + 1));
        final mutable = Map<String, String>.from(fragParams);
        if (mutable.remove(key) != null) {
          changed = true;
          final query = mutable.entries
              .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
              .join('&');
          fragment = query.isEmpty ? prefix : '$prefix?$query';
        }
      }

      if (!changed) return;

      // Use replaceState to avoid adding to browser history
      // This is critical: replaceState does NOT create a history entry,
      // so the back button won't revisit the URL with the token.
      final clean = uri.replace(
        queryParameters: params.isEmpty ? null : params,
        fragment: fragment.isEmpty ? null : fragment,
      ).toString();
      html.window.history.replaceState(null, html.document.title, clean);
    } catch (_) {}
  }

  static void removeQueryParams(Iterable<String> keys) {
    for (final key in keys) {
      removeQueryParam(key);
    }
  }

  // ── localStorage ──────────────────────────────

  static Map<String, dynamic>? readBarContext() {
    try {
      final raw = html.window.localStorage['bar_user_context'];
      if (raw != null && raw.isNotEmpty) return json.decode(raw) as Map<String, dynamic>;
    } catch (e) {
      print('[BAR] Failed to parse context: $e');
    }
    return null;
  }

  static String? readToken() {
    final ctx = readBarContext();
    final t = ctx?['token'] as String?;
    if (t != null && t.isNotEmpty) return t;
    final direct = html.window.localStorage['token'];
    if (direct != null && direct.isNotEmpty) return direct;
    if (DebugConfig.enabled && DebugConfig.token.isNotEmpty) return DebugConfig.token;
    return null;
  }

  static String? readStoredTransferToken() {
    try {
      final ctx = readBarContext();
      final fromCtx = (ctx?['transferToken'] ??
          ctx?['authTransferToken'] ??
          ctx?['transfer_token'])
          ?.toString()
          .trim();
      if (fromCtx != null && fromCtx.isNotEmpty) return fromCtx;
      return html.window.localStorage['bar_transfer_token'] ??
          html.window.localStorage['transferToken'] ??
          html.window.sessionStorage['bar_transfer_token'] ??
          html.window.sessionStorage['transferToken'];
    } catch (_) {
      return null;
    }
  }

  static String? readProductId() {
    final ctx = readBarContext();
    final p = ctx?['productId'] as String?;
    if (p != null && p.isNotEmpty) return p;
    if (DebugConfig.enabled && DebugConfig.productId.isNotEmpty) return DebugConfig.productId;
    return null;
  }

  // ── Logout Cleanup ────────────────────────────
  // Called when user logs out or session expires

  static void performLogoutCleanup() {
    try {
      // Remove auth-related storage
      html.window.localStorage.remove('token');
      html.window.localStorage.remove('bar_user_context');
      html.window.localStorage.remove('bar_transfer_token');
      html.window.sessionStorage.remove('bar_transfer_token');
      html.window.sessionStorage.remove('transferToken');

      // Dispatch logout event so any listening Flutter code can react
      html.window.dispatchEvent(html.CustomEvent('bar:logout'));

      // Notify Flutter bridge if available
      notifyFlutterBridge('LOG_EVENT', {
        'message': 'Designer logged out — session cleared',
      });

      print('[WebHelpers] Logout cleanup completed');
    } catch (e) {
      print('[WebHelpers] Logout cleanup error: $e');
    }
  }

  // ── Session Validation Helpers ────────────────

  /// Check if there's a valid JWT in localStorage
  static bool hasValidJwt() {
    final token = readToken();
    if (token == null || token.isEmpty) return false;

    // Parse JWT exp claim
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) normalized += '=';

      final decoded = jsonDecode(utf8.decode(base64Decode(normalized)))
      as Map<String, dynamic>;

      if (decoded['exp'] != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(
          (decoded['exp'] as num).toInt() * 1000,
          isUtc: true,
        );
        return expiry.isAfter(DateTime.now());
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clear session and redirect to app login
  static void redirectToLogin() {
    try {
      performLogoutCleanup();
      // The parent Flutter app handles navigation —
      // we just notify it and let it decide the destination.
      notifyFlutterBridge('SESSION_EXPIRED', {
        'reason': 'auth_required',
        'at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ── Event listeners ───────────────────────────

  static void onContextUpdated(void Function(Map<String, dynamic>) cb) {
    html.window.addEventListener('barContextUpdated', (html.Event e) {
      try {
        final detail = (e as html.CustomEvent).detail;
        if (detail != null) cb(json.decode(json.encode(detail)) as Map<String, dynamic>);
      } catch (_) {}
    });
  }

  static void onThemeChanged(void Function(String) cb) {
    html.window.addEventListener('barThemeChanged', (html.Event e) {
      try {
        final m = (e as html.CustomEvent).detail?.toString();
        if (m != null) cb(m);
      } catch (_) {}
    });
  }

  static void onLanguageChanged(void Function(String) cb) {
    html.window.addEventListener('barLanguageChanged', (html.Event e) {
      try {
        final l = (e as html.CustomEvent).detail?.toString();
        if (l != null) cb(l);
      } catch (_) {}
    });
  }

  // ── Browser utilities ─────────────────────────

  static Future<String?> pickColor(String initialColor) {
    final c = Completer<String?>();
    final input = html.InputElement()..type = 'color'..value = initialColor;
    void done([String? v]) { if (!c.isCompleted) c.complete(v); }
    input.onChange.first.then((_) => done(input.value));
    input.onBlur.first.then((_) => done(null));
    input.click();
    return c.future;
  }

  static Future<String?> pickImageAsDataUrl() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    final c = Completer<String?>();
    input.onChange.listen((_) {
      final file = input.files?.isNotEmpty == true ? input.files!.first : null;
      if (file == null) { if (!c.isCompleted) c.complete(null); return; }
      final reader = html.FileReader()..readAsDataUrl(file);
      reader.onLoad.first.then((_) { if (!c.isCompleted) c.complete(reader.result as String?); });
    });
    input.click();
    return c.future;
  }

  static void downloadDataUrl({required String dataUrl, required String fileName}) {
    final a = html.AnchorElement(href: dataUrl)..download = fileName..style.display = 'none';
    html.document.body?.append(a);
    a.click();
    a.remove();
  }
}
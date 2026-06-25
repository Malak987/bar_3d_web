import 'dart:js_interop';
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'debug_config.dart';

@JS('flutter_inappwebview')
external JSObject? get _flutterBridge;

@JS('flutter_inappwebview.callHandler')
external void _callHandler(JSString handlerName, JSAny? args);

class WebHelpers {
  WebHelpers._();

  // ── Flutter Bridge ────────────────────────────

  static bool get hasFlutterBridge {
    try {
      return _flutterBridge != null;
    } catch (_) {
      return false;
    }
  }

  static void notifyFlutterBridge(String type, Map<String, dynamic> payload) {
    try {
      if (hasFlutterBridge) {
        _callHandler('FlutterBridge'.toJS, {'type': type, 'payload': payload}.jsify());
      }
    } catch (e) {
      print('[BAR] FlutterBridge error: $e');
    }
  }

  static void notifyCustomizationAdded(Map<String, dynamic> result) {
    final payload = {
      'success': result['success'] == true,
      'cartUpdated': result['cartUpdated'] == true,
      'designImageUrl': result['designImageUrl'],
      'photoUrl': result['photoUrl'],
      'cartItemId': result['cartItemId'],
      // Additive production metadata; legacy listeners can ignore these keys.
      if (result.containsKey('finalPrice')) 'finalPrice': result['finalPrice'],
      if (result.containsKey('totalPrice')) 'totalPrice': result['totalPrice'],
      if (result.containsKey('customizationJson')) 'customizationJson': result['customizationJson'],
      if (result.containsKey('customizationMetadata')) 'customizationMetadata': result['customizationMetadata'],
    };
    try {
      if (hasFlutterBridge) {
        _callHandler('customizationAdded'.toJS, payload.jsify());
      }
      final message = {'source': 'bar3dcake', 'type': 'customizationAdded', 'payload': payload};
      html.window.postMessage(message, '*');
      if (html.window.parent != null) html.window.parent!.postMessage(message, '*');
    } catch (e) {
      print('[BAR] customizationAdded bridge error: $e');
    }
  }

  static void notifyCustomizationResult(Map<String, dynamic> result) {
    // Legacy bridge kept for old app builds only. New app builds should listen
    // to `customizationAdded`.
    try {
      if (hasFlutterBridge) {
        _callHandler('cakeCustomizationResult'.toJS, result.jsify());
      }
      final message = {'source': 'bar3dcake', 'type': 'cakeCustomizationResult', 'payload': result};
      html.window.postMessage(message, '*');
      if (html.window.parent != null) html.window.parent!.postMessage(message, '*');
    } catch (e) {
      print('[BAR] cakeCustomizationResult bridge error: $e');
    }
  }

  // ── URL query helpers ─────────────────────────

  static String? readQueryParam(String key) {
    try {
      String? fromUri(Uri uri) {
        final direct = uri.queryParameters[key];
        if (direct != null && direct.trim().isNotEmpty) return Uri.decodeComponent(direct.trim());

        // Some WebView/router combinations put query params after the hash:
        // /#/designer?transferToken=... or /#/?token=...
        final fragment = uri.fragment;
        final qIndex = fragment.indexOf('?');
        if (qIndex >= 0 && qIndex < fragment.length - 1) {
          final qp = Uri.splitQueryString(fragment.substring(qIndex + 1));
          final v = qp[key];
          if (v != null && v.trim().isNotEmpty) return Uri.decodeComponent(v.trim());
        }
        return null;
      }

      return fromUri(Uri.base) ?? fromUri(Uri.parse(html.window.location.href));
    } catch (_) {
      return null;
    }
  }

  static String? readFirstQueryParam(List<String> keys) {
    for (final key in keys) {
      final value = readQueryParam(key);
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

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

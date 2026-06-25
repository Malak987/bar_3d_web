import 'dart:js_interop';
import '../models/cake_config.dart';

/// Safe JS-interop bindings for `window.cakeDesigner.*`.
@JS('cakeDesigner')
external JSObject? get _bridge;

@JS('cakeDesigner.mount')
external void _mount(String containerId, JSAny config);

@JS('cakeDesigner.updateConfig')
external void _updateConfig(String containerId, JSAny config);

@JS('cakeDesigner.resetCamera')
external void _resetCamera(String containerId);

@JS('cakeDesigner.setQuality')
external void _setQuality(String containerId, String mode);

@JS('cakeDesigner.captureScreenshot')
external JSString? _captureScreenshot(String containerId, JSAny options);

@JS('cakeDesigner.capturePreviewImage')
external JSString? _capturePreviewImage(String containerId);

@JS('cakeDesigner.captureFinalImage')
external JSString? _captureFinalImage(String containerId);

@JS('cakeDesigner.exportCustomizationJSON')
external JSString? _exportCustomizationJSON(String containerId);

@JS('cakeDesigner.exportSelectedOptionsMetadata')
external JSString? _exportSelectedOptionsMetadata(String containerId, JSAny extra);

@JS('cakeDesigner.exportPackage')
external JSString? _exportPackage(String containerId, JSAny extra);

@JS('cakeDesigner.dispose')
external void _dispose(String containerId);

class CakeDesignerJs {
  CakeDesignerJs._();

  static bool get isReady {
    try { return _bridge != null; } catch (_) { return false; }
  }

  static void mount(String id, CakeConfig config) {
    if (!isReady) return _log('mount() → bridge not ready');
    try { _mount(id, config.toJson().jsify()!); } catch (e) { _log('mount() failed: $e'); }
  }

  static void updateConfig(String id, CakeConfig config) {
    if (!isReady) return;
    try { _updateConfig(id, config.toJson().jsify()!); } catch (e) { _log('updateConfig() failed: $e'); }
  }

  static void resetCamera(String id) {
    if (!isReady) return;
    try { _resetCamera(id); } catch (e) { _log('resetCamera() failed: $e'); }
  }

  static void setQuality(String id, String mode) {
    if (!isReady) return;
    try { _setQuality(id, mode); } catch (e) { _log('setQuality() failed: $e'); }
  }

  static String? captureScreenshot(String id, {int? width, int? height, String type = 'image/png', double quality = 0.92}) {
    if (!isReady) return null;
    try {
      final options = <String, Object?>{
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        'type': type,
        'quality': quality,
      };
      return _captureScreenshot(id, options.jsify()!)?.toDart;
    } catch (e) {
      _log('captureScreenshot() failed: $e');
      return null;
    }
  }

  static String? capturePreviewImage(String id) {
    if (!isReady) return null;
    try { return _capturePreviewImage(id)?.toDart; } catch (e) { _log('capturePreviewImage() failed: $e'); return null; }
  }

  static String? captureFinalImage(String id) {
    if (!isReady) return null;
    try { return _captureFinalImage(id)?.toDart; } catch (e) { _log('captureFinalImage() failed: $e'); return null; }
  }

  static String exportCustomizationJSON(String id) {
    if (!isReady) return '{}';
    try { return _exportCustomizationJSON(id)?.toDart ?? '{}'; } catch (e) { _log('exportCustomizationJSON() failed: $e'); return '{}'; }
  }

  static String exportSelectedOptionsMetadata(String id, Map<String, dynamic> extra) {
    if (!isReady) return '{}';
    try { return _exportSelectedOptionsMetadata(id, extra.jsify()!)?.toDart ?? '{}'; } catch (e) { _log('exportSelectedOptionsMetadata() failed: $e'); return '{}'; }
  }

  static String exportPackage(String id, Map<String, dynamic> extra) {
    if (!isReady) return '{}';
    try { return _exportPackage(id, extra.jsify()!)?.toDart ?? '{}'; } catch (e) { _log('exportPackage() failed: $e'); return '{}'; }
  }

  static void dispose(String id) {
    if (!isReady) return;
    try { _dispose(id); } catch (e) { _log('dispose() failed: $e'); }
  }

  static void _log(String msg) {
    // ignore: avoid_print
    print('[CakeDesignerJs] $msg');
  }
}

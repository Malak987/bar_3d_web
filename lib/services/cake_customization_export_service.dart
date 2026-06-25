import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

/// Production helper for host/ecommerce integration.
///
/// This file intentionally does NOT change the existing API service, Cubits, or
/// business payload builders. It provides optional generic REST/postMessage
/// methods that a host app can call when embedding the configurator in Flutter
/// Web, WebView, or iframe.
class CakeCustomizationExportService {
  CakeCustomizationExportService._();

  static Future<Map<String, dynamic>> uploadFinalImage({
    required Uri endpoint,
    required String dataUrl,
    Map<String, String> headers = const {},
    Map<String, dynamic> extraFields = const {},
  }) => uploadDataUrl(
        endpoint: endpoint,
        fieldName: 'finalImage',
        dataUrl: dataUrl,
        headers: headers,
        extraFields: extraFields,
      );

  static Future<Map<String, dynamic>> uploadPreviewImage({
    required Uri endpoint,
    required String dataUrl,
    Map<String, String> headers = const {},
    Map<String, dynamic> extraFields = const {},
  }) => uploadDataUrl(
        endpoint: endpoint,
        fieldName: 'previewImage',
        dataUrl: dataUrl,
        headers: headers,
        extraFields: extraFields,
      );

  static Future<Map<String, dynamic>> uploadDesignJson({
    required Uri endpoint,
    required Map<String, dynamic> designJson,
    Map<String, String> headers = const {},
  }) => postJson(endpoint: endpoint, body: designJson, headers: headers);

  static Future<Map<String, dynamic>> uploadCustomizationMetadata({
    required Uri endpoint,
    required Map<String, dynamic> metadata,
    required num finalPrice,
    Map<String, String> headers = const {},
  }) => postJson(endpoint: endpoint, body: {...metadata, 'finalPrice': finalPrice}, headers: headers);

  static String? customizationIdFromResponse(Map<String, dynamic> response) =>
      (response['customizationId'] ?? response['id'] ?? response['data']?['id'])?.toString();

  static Future<Map<String, dynamic>> uploadDataUrl({
    required Uri endpoint,
    required String fieldName,
    required String dataUrl,
    Map<String, String> headers = const {},
    Map<String, dynamic> extraFields = const {},
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final request = html.HttpRequest();
    final form = html.FormData();
    extraFields.forEach((key, value) => form.append(key, value?.toString() ?? ''));

    final blob = _dataUrlToBlob(dataUrl);
    final extension = blob.type == 'image/jpeg' ? 'jpg' : 'png';
    form.appendBlob(fieldName, blob, '$fieldName-${DateTime.now().millisecondsSinceEpoch}.$extension');

    final completer = Completer<Map<String, dynamic>>();
    request
      ..open('POST', endpoint.toString())
      ..responseType = 'text';
    headers.forEach(request.setRequestHeader);
    request.onLoad.listen((_) {
      if (request.status != null && request.status! >= 200 && request.status! < 300) {
        completer.complete(_decodeResponse(request.responseText));
      } else {
        completer.completeError(StateError('Upload failed: HTTP ${request.status} ${request.responseText ?? ''}'));
      }
    });
    request.onError.listen((_) => completer.completeError(StateError('Network error while uploading $fieldName')));
    request.send(form);
    return completer.future.timeout(timeout);
  }

  static Future<Map<String, dynamic>> postJson({
    required Uri endpoint,
    required Map<String, dynamic> body,
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final request = html.HttpRequest();
    final completer = Completer<Map<String, dynamic>>();
    request
      ..open('POST', endpoint.toString())
      ..responseType = 'text'
      ..setRequestHeader('Content-Type', 'application/json');
    headers.forEach(request.setRequestHeader);
    request.onLoad.listen((_) {
      if (request.status != null && request.status! >= 200 && request.status! < 300) {
        completer.complete(_decodeResponse(request.responseText));
      } else {
        completer.completeError(StateError('POST failed: HTTP ${request.status} ${request.responseText ?? ''}'));
      }
    });
    request.onError.listen((_) => completer.completeError(StateError('Network error while posting JSON')));
    request.send(jsonEncode(body));
    return completer.future.timeout(timeout);
  }

  static Future<String?> createCustomization({
    required Uri finalImageEndpoint,
    required Uri previewImageEndpoint,
    required Uri designJsonEndpoint,
    required Uri metadataEndpoint,
    required String finalImageDataUrl,
    required String previewImageDataUrl,
    required Map<String, dynamic> designJson,
    required Map<String, dynamic> metadata,
    required num finalPrice,
    Map<String, String> headers = const {},
  }) async {
    final finalUpload = await uploadFinalImage(endpoint: finalImageEndpoint, dataUrl: finalImageDataUrl, headers: headers);
    final previewUpload = await uploadPreviewImage(endpoint: previewImageEndpoint, dataUrl: previewImageDataUrl, headers: headers);
    final designUpload = await uploadDesignJson(endpoint: designJsonEndpoint, designJson: designJson, headers: headers);
    final metaUpload = await uploadCustomizationMetadata(endpoint: metadataEndpoint, metadata: {
      ...metadata,
      'finalImage': finalUpload,
      'previewImage': previewUpload,
      'designJson': designUpload,
    }, finalPrice: finalPrice, headers: headers);

    return customizationIdFromResponse(metaUpload);
  }

  static void postMessageToHost(String type, Map<String, dynamic> payload, {String targetOrigin = '*'}) {
    html.window.parent?.postMessage({'source': 'bar3dcake', 'type': type, 'payload': payload}, targetOrigin);
  }

  static html.Blob _dataUrlToBlob(String dataUrl) {
    final parts = dataUrl.split(',');
    if (parts.length < 2) throw ArgumentError('Invalid data URL');
    final meta = parts.first;
    final mime = RegExp(r'data:([^;]+)').firstMatch(meta)?.group(1) ?? 'application/octet-stream';
    final bytes = base64Decode(parts.sublist(1).join(','));
    return html.Blob([bytes], mime);
  }

  static Map<String, dynamic> _decodeResponse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : {'data': decoded};
  }
}

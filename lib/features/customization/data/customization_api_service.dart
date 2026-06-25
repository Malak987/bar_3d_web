import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import '../../../services/api_service.dart';
import 'customization_models.dart';

class CustomizationApiService {
  Future<CustomizationCartModel> getCart() async {
    final json = await _request('GET', '/api/CustomizationCart/GetCart');
    return CustomizationCartModel.fromJson(_data(json));
  }

  Future<void> removeFromCart(String cartItemId) async {
    await _request('DELETE', '/api/CustomizationCart/RemoveFromCart/$cartItemId');
  }

  Future<String> placeOrder(Map<String, dynamic> payload) async {
    final json = await _request('POST', '/api/CustomizationOrder/PlaceOrder', body: payload);
    final data = _data(json);
    if (data is Map) {
      return (data['orderId'] ?? data['id'] ?? data['orderNumber'] ?? '').toString();
    }
    return '';
  }

  Future<List<CustomizationOrderModel>> getMyOrders() async {
    final json = await _request('GET', '/api/CustomizationOrder/GetMyOrders');
    final data = _data(json);
    final list = data is List
        ? data
        : data is Map && data['items'] is List
            ? data['items'] as List
            : data is Map && data['orders'] is List
                ? data['orders'] as List
                : const [];
    return list.map((e) => CustomizationOrderModel.fromJson(e)).toList();
  }

  dynamic _data(dynamic json) {
    if (json is Map && json.containsKey('data')) return json['data'];
    return json;
  }

  Future<dynamic> _request(String method, String path, {Map<String, dynamic>? body}) async {
    final req = html.HttpRequest();
    req.open(method, '${ApiService.baseUrl}$path');
    final token = ApiService.token;
    req.withCredentials = token == null || token.isEmpty;
    req.setRequestHeader('Accept', 'application/json');
    if (body != null) req.setRequestHeader('Content-Type', 'application/json');
    if (token != null && token.isNotEmpty) {
      req.setRequestHeader('Authorization', 'Bearer $token');
    }

    final completer = Completer<dynamic>();
    req.onLoad.listen((_) {
      final status = req.status;
      final text = req.responseText ?? '';
      final decoded = _decode(text);


      if (status == null || status < 200 || status >= 300) {
        final msg = decoded is Map
            ? (decoded['message'] ?? decoded['error'] ?? text).toString()
            : text;

        completer.completeError(
          Exception(msg.isEmpty ? 'Request failed: ${status ?? "unknown"}' : msg),
        );
        return;
      }
      if (decoded is Map && decoded['isSucceeded'] == false) {
        completer.completeError(Exception((decoded['message'] ?? 'Request failed').toString()));
        return;
      }
      completer.complete(decoded);
    });
    req.onError.listen((_) => completer.completeError(Exception('Network error')));
    req.send(body == null ? null : jsonEncode(body));
    return completer.future;
  }

  dynamic _decode(String text) {
    try { return jsonDecode(text); } catch (_) { return text; }
  }
}

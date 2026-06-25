import 'customization_api_service.dart';
import 'customization_models.dart';

class CustomizationRepository {
  final CustomizationApiService api;
  CustomizationRepository({CustomizationApiService? api}) : api = api ?? CustomizationApiService();

  Future<CustomizationCartModel> getCart() => api.getCart();
  Future<void> removeFromCart(String id) => api.removeFromCart(id);
  Future<String> placeOrder(Map<String, dynamic> payload) => api.placeOrder(payload);
  Future<List<CustomizationOrderModel>> getMyOrders() => api.getMyOrders();
}

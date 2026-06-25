import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/customization_repository.dart';

abstract class CustomizationCheckoutState { const CustomizationCheckoutState(); }
class CustomizationCheckoutInitial extends CustomizationCheckoutState { const CustomizationCheckoutInitial(); }
class CustomizationCheckoutLoading extends CustomizationCheckoutState { const CustomizationCheckoutLoading(); }
class CustomizationCheckoutSuccess extends CustomizationCheckoutState {
  final String orderId;
  const CustomizationCheckoutSuccess(this.orderId);
}
class CustomizationCheckoutError extends CustomizationCheckoutState {
  final String message;
  const CustomizationCheckoutError(this.message);
}

class CustomizationCheckoutCubit extends Cubit<CustomizationCheckoutState> {
  final CustomizationRepository repo;
  CustomizationCheckoutCubit({CustomizationRepository? repo})
      : repo = repo ?? CustomizationRepository(),
        super(const CustomizationCheckoutInitial());

  Future<void> placeOrder(Map<String, dynamic> payload) async {
    emit(const CustomizationCheckoutLoading());
    try { emit(CustomizationCheckoutSuccess(await repo.placeOrder(payload))); }
    catch (e) { emit(CustomizationCheckoutError(e.toString())); }
  }
}

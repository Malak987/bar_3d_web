import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/customization_models.dart';
import '../data/customization_repository.dart';

abstract class CustomizationCartState { const CustomizationCartState(); }
class CustomizationCartInitial extends CustomizationCartState { const CustomizationCartInitial(); }
class CustomizationCartLoading extends CustomizationCartState { const CustomizationCartLoading(); }
class CustomizationCartLoaded extends CustomizationCartState {
  final CustomizationCartModel cart;
  const CustomizationCartLoaded(this.cart);
}
class CustomizationCartError extends CustomizationCartState {
  final String message;
  const CustomizationCartError(this.message);
}

class CustomizationCartCubit extends Cubit<CustomizationCartState> {
  final CustomizationRepository repo;
  CustomizationCartCubit({CustomizationRepository? repo})
      : repo = repo ?? CustomizationRepository(),
        super( CustomizationCartInitial());

  Future<void> load() async {
    emit(const CustomizationCartLoading());
    try { emit(CustomizationCartLoaded(await repo.getCart())); }
    catch (e) { emit(CustomizationCartError(e.toString())); }
  }

  Future<void> remove(String id) async {
    try {
      await repo.removeFromCart(id);
      await load();
    } catch (e) { emit(CustomizationCartError(e.toString())); }
  }
}

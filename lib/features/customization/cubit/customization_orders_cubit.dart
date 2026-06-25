import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/customization_models.dart';
import '../data/customization_repository.dart';

abstract class CustomizationOrdersState { const CustomizationOrdersState(); }
class CustomizationOrdersInitial extends CustomizationOrdersState { const CustomizationOrdersInitial(); }
class CustomizationOrdersLoading extends CustomizationOrdersState { const CustomizationOrdersLoading(); }
class CustomizationOrdersLoaded extends CustomizationOrdersState {
  final List<CustomizationOrderModel> orders;
  const CustomizationOrdersLoaded(this.orders);
}
class CustomizationOrdersError extends CustomizationOrdersState {
  final String message;
  const CustomizationOrdersError(this.message);
}

class CustomizationOrdersCubit extends Cubit<CustomizationOrdersState> {
  final CustomizationRepository repo;
  CustomizationOrdersCubit({CustomizationRepository? repo})
      : repo = repo ?? CustomizationRepository(),
        super(const CustomizationOrdersInitial());

  Future<void> load() async {
    emit(const CustomizationOrdersLoading());
    try { emit(CustomizationOrdersLoaded(await repo.getMyOrders())); }
    catch (e) { emit(CustomizationOrdersError(e.toString())); }
  }
}

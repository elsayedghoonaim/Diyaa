import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../progress/presentation/manager/progress_cubit.dart';
import '../../../progress/presentation/manager/progress_state.dart';
import '../../data/models/shop_model.dart';
import '../../data/repo/shop_repository.dart';
import 'shop_state.dart';

class ShopCubit extends Cubit<ShopState> {
  final ShopRepository _shopRepository;
  final ProgressCubit _progressCubit;

  ShopCubit({
    required ShopRepository shopRepository,
    required ProgressCubit progressCubit,
  })  : _shopRepository = shopRepository,
        _progressCubit = progressCubit,
        super(const ShopInitial());

  Future<void> loadShop() async {
    emit(const ShopLoading());
    try {
      final ShopModel shop = await _shopRepository.loadShop();
      emit(ShopLoaded(shop));
    } catch (error) {
      emit(ShopError('Failed to load shop settings: $error'));
    }
  }

  Future<bool> purchaseTheme(String themeId, int cost) async {
    final ProgressState progressState = _progressCubit.state;
    if (progressState is! ProgressLoaded) {
      return false;
    }
    if (progressState.progress.totalPoints < cost) {
      return false;
    }
    final ShopState current = state;
    if (current is! ShopLoaded) {
      return false;
    }
    emit(const ShopLoading());
    try {
      await _progressCubit.deductPoints(cost);
      final ShopModel updated = await _shopRepository.purchaseTheme(current.shop, themeId);
      emit(ShopLoaded(updated));
      return true;
    } catch (error) {
      emit(ShopError('Theme purchase failed: $error'));
      return false;
    }
  }

  Future<void> applyTheme(String themeId) async {
    final ShopState current = state;
    if (current is! ShopLoaded) {
      return;
    }
    try {
      final ShopModel updated = await _shopRepository.applyTheme(current.shop, themeId);
      emit(ShopLoaded(updated));
    } catch (error) {
      emit(ShopError('Failed to apply theme: $error'));
    }
  }

  Future<bool> purchaseAudio(String audioId, int cost) async {
    final ProgressState progressState = _progressCubit.state;
    if (progressState is! ProgressLoaded) {
      return false;
    }
    if (progressState.progress.totalPoints < cost) {
      return false;
    }
    final ShopState current = state;
    if (current is! ShopLoaded) {
      return false;
    }
    emit(const ShopLoading());
    try {
      await _progressCubit.deductPoints(cost);
      final ShopModel updated = await _shopRepository.purchaseAudio(current.shop, audioId);
      emit(ShopLoaded(updated));
      return true;
    } catch (error) {
      emit(ShopError('Audio purchase failed: $error'));
      return false;
    }
  }

  Future<void> applyAudio(String audioId) async {
    final ShopState current = state;
    if (current is! ShopLoaded) {
      return;
    }
    try {
      final ShopModel updated = await _shopRepository.applyAudio(current.shop, audioId);
      emit(ShopLoaded(updated));
    } catch (error) {
      emit(ShopError('Failed to apply audio: $error'));
    }
  }
}

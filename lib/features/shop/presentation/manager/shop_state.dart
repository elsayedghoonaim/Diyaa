import '../../data/models/shop_model.dart';

sealed class ShopState {
  const ShopState();
}

final class ShopInitial extends ShopState {
  const ShopInitial();
}

final class ShopLoading extends ShopState {
  const ShopLoading();
}

final class ShopLoaded extends ShopState {
  final ShopModel shop;
  const ShopLoaded(this.shop);
}

final class ShopError extends ShopState {
  final String message;
  const ShopError(this.message);
}

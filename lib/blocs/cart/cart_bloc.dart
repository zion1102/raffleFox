import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:raffle_fox/services/cart_service.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class CartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCartItems extends CartEvent {}

class CheckoutCart extends CartEvent {}

// States
abstract class CartState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<Map<String, dynamic>> cartItems;
  final double total;

  CartLoaded(this.cartItems, this.total);

  @override
  List<Object?> get props => [cartItems, total];
}

class CartError extends CartState {
  final String message;

  CartError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class CartBloc extends Bloc<CartEvent, CartState> {
  final CartService cartService;

  CartBloc({required this.cartService}) : super(CartLoading()) {
    on<LoadCartItems>(_onLoadCartItems);
    on<CheckoutCart>(_onCheckoutCart);
  }

  Future<void> _onLoadCartItems(LoadCartItems event, Emitter<CartState> emit) async {
    try {
      emit(CartLoading());
      final userId = await cartService.getCurrentUserId();
      if (userId == null) {
        emit(CartError("User not found."));
        return;
      }
      final cartItems = await cartService.getCartItemsForUser(userId);
      final cartTotal = await cartService.calculateCartTotal(userId);
      emit(CartLoaded(cartItems, cartTotal.toDouble()));
    } catch (e) {
      emit(CartError("Failed to load cart items: $e"));
    }
  }

  Future<void> _onCheckoutCart(CheckoutCart event, Emitter<CartState> emit) async {
  try {
    emit(CartLoading());
    final userId = await cartService.getCurrentUserId();
    if (userId == null) {
      emit(CartError("User not found."));
      return;
    }

    // Calculate the total price of cart items
    final cartItems = await cartService.getCartItemsForUser(userId);
    final totalPrice = await cartService.calculateCartTotal(userId);

    // Check if the user has enough credits
    final hasEnoughCredits = await cartService.deductCredits(userId, totalPrice);
    if (!hasEnoughCredits) {
      emit(CartError("Insufficient credits. Please add more credits."));
      return;
    }

    // Proceed with checkout if credits are sufficient
    await cartService.checkoutCart(userId);

    // Emit the updated state after checkout
    emit(CartLoaded([], 0.0)); // Reset cart after successful checkout
  } catch (e) {
    emit(CartError("Failed to checkout: $e"));
  }
}

}

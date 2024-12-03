import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:raffle_fox/services/cart_service.dart';
import 'package:raffle_fox/blocs/cart/cart_bloc.dart';
import 'package:raffle_fox/widgets/ProfileAppBar.dart';
import 'package:raffle_fox/widgets/BottomNavBar.dart';
import 'package:raffle_fox/widgets/RaffleTicket.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CartBloc(cartService: CartService())..add(LoadCartItems()),
      child: Scaffold(
        appBar: const ProfileAppBar(),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state is CartLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CartLoaded) {
              if (state.cartItems.isEmpty) {
                return const Center(child: Text("No items in cart."));
              }

              final now = DateTime.now();

              // Combine tickets of the same raffle and exclude expired raffles
              final Map<String, Map<String, dynamic>> combinedRaffles = {};

              for (var item in state.cartItems) {
                final expiryDate = item['expiryDate']?.toDate();

                if (expiryDate != null && expiryDate.isAfter(now)) {
                  final raffleId = item['raffleId'];

                  if (raffleId != null) {
                    if (combinedRaffles.containsKey(raffleId)) {
                      combinedRaffles[raffleId]!['tickets'] =
                          (combinedRaffles[raffleId]!['tickets'] ?? 0) + 1;
                      combinedRaffles[raffleId]!['totalPrice'] =
                          (combinedRaffles[raffleId]!['totalPrice'] ?? 0.0) +
                              (item['price'] ?? 0.0);
                    } else {
                      combinedRaffles[raffleId] = {
                        'raffleId': raffleId,
                        'raffleTitle': item['raffleTitle'] ?? 'Unknown',
                        'expiryDate': expiryDate,
                        'tickets': 1,
                        'totalPrice': item['price'] ?? 0.0,
                      };
                    }
                  }
                }
              }

              final validRaffles = combinedRaffles.values.toList();

              // Calculate the total price of valid raffles
              final totalPrice = validRaffles.fold<double>(
                0.0,
                (sum, item) => sum + (item['totalPrice'] ?? 0.0),
              );

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: validRaffles.length,
                      itemBuilder: (context, index) {
                        final raffle = validRaffles[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: RaffleTicket(
                            raffleId: raffle['raffleId'],
                            expiryDate: raffle['expiryDate'],
                            title: raffle['raffleTitle'],
                            guesses: raffle['tickets'],
                            totalPrice: raffle['totalPrice'],
                          ),
                        );
                      },
                    ),
                  ),
                  // Checkout Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 20.0),
                    child: SizedBox(
                      width: double.infinity,
                      child:ElevatedButton(
  onPressed: validRaffles.isEmpty
      ? null // Disable if no valid raffles
      : () {
          context.read<CartBloc>().add(CheckoutCart());
        },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFFF5F00),
    padding: const EdgeInsets.symmetric(vertical: 16.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
  ),
  child: Text(
    validRaffles.isEmpty
        ? "No valid items to checkout"
        : "Checkout - \$${totalPrice.toStringAsFixed(2)}",
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
),

                    ),
                  ),
                ],
              );
            } else if (state is CartError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            } else {
              return const Center(child: Text("Unexpected state."));
            }
          },
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:raffle_fox/services/cart_service.dart';
import 'package:raffle_fox/services/firebase_services.dart';
import 'package:raffle_fox/widgets/BottomNavBar.dart';
import 'package:raffle_fox/widgets/ProfileAppBar.dart';
import 'package:raffle_fox/widgets/RaffleTicket.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> cartItems = [];
  bool loading = true;
  double cartTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    final user = await _firebaseService.getUserDetails();
    if (user != null) {
      final userId = user['uid'];
      cartItems = await _cartService.getCartItemsForUser(userId);
      cartTotal = await _cartService.calculateCartTotal(userId);
    }
    setState(() {
      loading = false;
    });
  }

  void _showCheckoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Checkout Confirmation"),
        content: Text("Proceed to checkout with a total of \$${cartTotal.toStringAsFixed(2)}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleCheckout();
            },
            child: const Text("Yes, Checkout"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout() async {
    setState(() {
      loading = true;
    });

    final user = await _firebaseService.getUserDetails();
    if (user != null) {
      final userId = user['uid'];
      await _cartService.checkoutCart(userId);
      cartItems.clear();
      cartTotal = 0.0;
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Checkout successful!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ProfileAppBar(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? const Center(child: Text("No items in cart."))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final expiryDate = item['expiryDate'].toDate();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: RaffleTicket(
                              raffleId: item['raffleId'],
                              expiryDate: expiryDate,
                              title: item['raffleTitle'],
                              guesses: 1,
                              totalPrice: item['price'] ?? 0.0,
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: cartItems.isNotEmpty ? _showCheckoutDialog : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            backgroundColor: const Color(0xFFFF5F00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: Text(
                            "Checkout - \$${cartTotal.toStringAsFixed(2)}",
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
                ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

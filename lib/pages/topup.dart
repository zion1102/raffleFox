import 'package:flutter/material.dart';
import 'package:raffle_fox/services/firebase_services.dart';

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  int userCredits = 0; // Track the user's current credits

  final topUpOptions = [
    {'credits': 1, 'price': 20.0},
    {'credits': 5, 'price': 100.0},
    {'credits': 10, 'price': 200.0},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserCredits(); // Fetch user credits when the page loads
  }

  Future<void> _fetchUserCredits() async {
    try {
      final userId = await FirebaseService().getCurrentUserId();
      if (userId != null) {
        final userDetails = await FirebaseService().getUserDetails();
        if (userDetails != null && userDetails.containsKey('credits')) {
          setState(() {
            userCredits = userDetails['credits'] as int; // Update user credits
          });
        }
      }
    } catch (e) {
      print("Error fetching user credits: $e");
    }
  }

  Future<void> _confirmPurchase(num? credits) async {
    // Ensure credits is converted to int and handle null case
    int? intCredits = credits?.toInt();
    if (intCredits == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Purchase"),
        content: Text("Do you want to add $intCredits credit(s) to your account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userId = await FirebaseService().getCurrentUserId(); // Fetch current user's ID
      if (userId != null) {
        // Add credits to Firestore
        final updatedCredits = (userCredits + intCredits).toInt();
        await FirebaseService().updateUserCredits(userId, updatedCredits);

        // Update local state
        setState(() {
          userCredits += intCredits; // Update credits locally
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$intCredits credit(s) added to your account!"),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: Unable to fetch user ID."),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Up'),
        backgroundColor: const Color(0xFFFF5F00),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Purchase Credits",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: topUpOptions.length,
                itemBuilder: (context, index) {
                  final option = topUpOptions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5F00),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _confirmPurchase(option['credits']),
                      child: Text(
                        "${option['credits']} Credit(s) - \$${option['price']}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Your Credits: $userCredits",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

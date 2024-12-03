// likedRafflePage.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raffle_fox/services/firebase_services.dart';
import 'package:raffle_fox/pages/raffle_detail.dart';
import 'package:raffle_fox/widgets/ProfileAppBar.dart';
import 'package:raffle_fox/widgets/BottomNavBar.dart';
import 'dart:async';

class LikedRafflePage extends StatefulWidget {
  const LikedRafflePage({Key? key}) : super(key: key);

  @override
  _LikedRafflePageState createState() => _LikedRafflePageState();
}

class _LikedRafflePageState extends State<LikedRafflePage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> likedRaffles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLikedRaffles();
  }

  Future<void> _fetchLikedRaffles() async {
    try {
      List<Map<String, dynamic>> fetchedRaffles = await _firebaseService.getRecentLikedRaffles();

      setState(() {
        likedRaffles = fetchedRaffles.map((raffle) {
          final expiryDate = raffle['expiryDate'] is Timestamp
              ? (raffle['expiryDate'] as Timestamp).toDate()
              : (raffle['expiryDate'] != null && raffle['expiryDate'] is String)
                  ? DateTime.tryParse(raffle['expiryDate']) ?? DateTime.now()
                  : DateTime.now();

          raffle['expiryDate'] = expiryDate;
          return raffle;
        }).where((raffle) => raffle['expiryDate'].isAfter(DateTime.now())).toList();

        isLoading = false;
      });
    } catch (e) {
      print("Error fetching liked raffles: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatTimeLeft(Duration duration) {
    final days = duration.inDays.toString().padLeft(2, '0');
    final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$days:$hours:$minutes:$seconds";
  }

  Widget _buildCountdown(DateTime expiryDate) {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text("Loading...");
        }
        final now = snapshot.data!;
        final timeLeft = expiryDate.difference(now);
        if (timeLeft.isNegative) {
          return const Text("Expired", style: TextStyle(color: Colors.red));
        }
        return Text(
          _formatTimeLeft(timeLeft),
          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ProfileAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : likedRaffles.isEmpty
              ? const Center(child: Text("No liked raffles found."))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: likedRaffles.length,
                    itemBuilder: (context, index) {
                      final raffle = likedRaffles[index];
                      final expiryDate = raffle['expiryDate'] as DateTime;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RaffleDetailScreen(raffleData: raffle),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: Image.network(
                                  raffle['picture'] ?? 'https://via.placeholder.com/150',
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      raffle['title'] ?? "No Title",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "Time Left:",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        _buildCountdown(expiryDate),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

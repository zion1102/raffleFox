import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raffle_fox/pages/raffle_detail.dart';
// Import this for Timestamp handling

class LatestRaffles extends StatelessWidget {
  const LatestRaffles({super.key});

  Future<List<Map<String, dynamic>>> fetchLatestRaffles() async {
    // Fetch the latest six raffles with a future expiry date from Firestore
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('raffles')
        .where('expiryDate', isGreaterThan: Timestamp.now()) // Only fetch raffles with future expiry dates
        .orderBy('expiryDate', descending: false) // Order by nearest expiry date
        .limit(6)
        .get();

    // Map the documents to a list of raffle data maps
    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchLatestRaffles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error fetching raffles'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(); // Return an empty container if no data
        }

        List<Map<String, dynamic>> raffles = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Latest Raffles',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF15B29),
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        "See All",
                        style: TextStyle(
                          color: Color(0xFF202020),
                          fontSize: 14,
                          fontFamily: 'Gotham',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        'assets/images/Button.svg', // Using SVG here
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var raffle in raffles) buildRaffleItem(context, raffle),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildRaffleItem(BuildContext context, Map<String, dynamic> raffleData) {
    // Check if 'expiryDate' is a Timestamp and convert it to DateTime
    DateTime expiryDate = (raffleData['expiryDate'] is Timestamp)
        ? (raffleData['expiryDate'] as Timestamp).toDate()
        : DateTime.parse(raffleData['expiryDate']);

    return Padding(
      padding: const EdgeInsets.only(right: 10.0, bottom: 16.0), // Adjust padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              // Navigate to the raffle detail screen when the image is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RaffleDetailScreen(raffleData: raffleData),
                ),
              );
            },
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 130,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.grey,
                    image: DecorationImage(
                      image: NetworkImage(raffleData['picture'] ?? 'https://via.placeholder.com/370x160.png/cccccc/ffffff?text=No+raffles+availabled'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  raffleData['title'] ?? "No title",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                CountdownTimer(expiryDate: expiryDate),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    // Navigate to the raffle detail screen when "Play Now" is tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RaffleDetailScreen(raffleData: raffleData),
                      ),
                    );
                  },
                  child: const Text(
                    "Play Now",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CountdownTimer extends StatefulWidget {
  final DateTime expiryDate;

  const CountdownTimer({super.key, required this.expiryDate});

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Duration _remainingTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.expiryDate.difference(DateTime.now());

    // Update the countdown every second
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _remainingTime = widget.expiryDate.difference(DateTime.now());

        // If time is up, stop the countdown
        if (_remainingTime.isNegative) {
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate days, hours, minutes, and seconds
    int days = _remainingTime.inDays;
    int hours = _remainingTime.inHours % 24;
    int minutes = _remainingTime.inMinutes % 60;
    int seconds = _remainingTime.inSeconds % 60;

    // Format the time as dd:hh:mm:ss
    String timeLeft = '${days.toString().padLeft(2, '0')}:${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Text(
      timeLeft,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

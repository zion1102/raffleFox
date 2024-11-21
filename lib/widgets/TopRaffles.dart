import 'dart:async';

import 'package:flutter/material.dart';
import 'package:raffle_fox/services/raffle_service.dart';
import 'package:raffle_fox/pages/raffle_detail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Import this for Timestamp handling

class TopRaffles extends StatefulWidget {
  const TopRaffles({super.key});

  @override
  _TopRafflesState createState() => _TopRafflesState();
}

class _TopRafflesState extends State<TopRaffles> {
  final RaffleService _raffleService = RaffleService();
  late Future<List<Map<String, dynamic>>> _topRafflesFuture;

  @override
  void initState() {
    super.initState();
    _topRafflesFuture = _fetchTopRaffles();
  }

  Future<List<Map<String, dynamic>>> _fetchTopRaffles() async {
    print("Attempting to fetch top raffles...");
    return await _raffleService.getTopRaffles();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _topRafflesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          print("Error loading top raffles: ${snapshot.error}");
          return Container(); // Display nothing on error
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(); // Display nothing if no data is returned
        }

        List<Map<String, dynamic>> raffles = snapshot.data!;

        // Calculate the size of each raffle square based on the screen width
        double screenWidth = MediaQuery.of(context).size.width;
        double squareSize = (screenWidth) / 5; // Padding of 20 on each side, 3 items per row

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Raffles',
                style: TextStyle(
                  color: Color(0xFFF15B29),
                  fontSize: 21,
                  fontFamily: 'Gibson',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: raffles.map((raffle) => _buildRaffleSquare(context, raffle, squareSize)).toList(),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildRaffleSquare(BuildContext context, Map<String, dynamic> raffle, double size) {
    // Check if 'expiryDate' is a Timestamp and convert it to DateTime
    DateTime expiryDate = (raffle['expiryDate'] is Timestamp)
        ? (raffle['expiryDate'] as Timestamp).toDate()
        : DateTime.parse(raffle['expiryDate']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RaffleDetailScreen(raffleData: raffle),
          ),
        );
      },
      child: Column(
        children: [
          // Image Container
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(raffle['picture'] ?? 'https://via.placeholder.com/150'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8), // Space between the image and the timer
          // Countdown Timer below the image
          CountdownTimer(expiryDate: expiryDate),
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

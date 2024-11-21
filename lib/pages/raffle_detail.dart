import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:raffle_fox/pages/game_screen.dart';
import 'package:raffle_fox/widgets/BottomNavBar.dart';
import 'package:raffle_fox/widgets/ProfileAppBar.dart';

class RaffleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> raffleData;

  const RaffleDetailScreen({super.key, required this.raffleData});

  @override
  _RaffleDetailScreenState createState() => _RaffleDetailScreenState();
}

class _RaffleDetailScreenState extends State<RaffleDetailScreen> {
  late Timer _timer;
  Duration _timeLeft = const Duration();
  bool isLiked = false; // Track if the user has liked the raffle

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _checkIfLiked(); // Check if the raffle is liked by the current user
  }

  void _startCountdown() {
    DateTime expiryDate = widget.raffleData['expiryDate'].toDate(); // Convert from Firebase timestamp
    DateTime now = DateTime.now();
    if (expiryDate.isAfter(now)) {
      _timeLeft = expiryDate.difference(now);

      // Update the timer every second
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft.inSeconds > 0) {
          setState(() {
            _timeLeft = _timeLeft - const Duration(seconds: 1);
          });
        } else {
          timer.cancel();
        }
      });
    }
  }

 Future<void> _checkIfLiked() async {
  final user = FirebaseAuth.instance.currentUser;
  final raffleId = widget.raffleData['raffleId'];

  if (user == null || raffleId == null) {
    print("Error: raffleId is null in _checkIfLiked");
    return;
  }

  final likeDoc = await FirebaseFirestore.instance
      .collection('userLikes')
      .doc('${user.uid}_$raffleId')
      .get();

  setState(() {
    isLiked = likeDoc.exists;
  });
}

Future<void> _toggleLike() async {
  final user = FirebaseAuth.instance.currentUser;
  final raffleId = widget.raffleData['raffleId'];

  if (user == null || raffleId == null) {
    print("Error: raffleId is null in _toggleLike");
    return;
  }

  final likeRef = FirebaseFirestore.instance.collection('userLikes').doc('${user.uid}_$raffleId');

  if (isLiked) {
    await likeRef.delete();
    print("Like removed for raffleId: $raffleId");
  } else {
    await likeRef.set({
      'raffleId': raffleId,
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'expiryDate': widget.raffleData['expiryDate'],
      'title': widget.raffleData['title'],
      'imageUrl': widget.raffleData['picture'],
    });
    print("Like added for raffleId: $raffleId");
  }

  setState(() {
    isLiked = !isLiked;
  });
}


  @override
  void dispose() {
    _timer.cancel(); // Make sure to cancel the timer to avoid memory leaks
    super.dispose();
  }

  // Helper function to format the time dynamically
  String _formatTime(Duration duration) {
    if (duration.inHours >= 48) {
      int days = duration.inDays;
      int hours = duration.inHours.remainder(24);
      int minutes = duration.inMinutes.remainder(60);
      return '${days}d ${hours}h ${minutes}m';
    } else {
      String hours = duration.inHours.toString().padLeft(2, '0');
      String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
      String seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ProfileAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image and Heart Icon
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xff222222),
                              image: DecorationImage(
                                image: NetworkImage(widget.raffleData['picture']),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: _toggleLike, // Toggle like status on tap
                              child: SvgPicture.asset(
                                'assets/images/vector.svg',
                                width: 40,
                                height: 40,
                                color: isLiked ? Colors.red : Colors.white, // Change color based on like status
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // View Video button action
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9500),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              ),
                              icon: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                              label: const Text(
                                'View Video',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Title and Timer
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.raffleData['title'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.timer, color: Colors.black, size: 24),
                              const SizedBox(width: 10),
                              _buildTimerBox(_formatTime(_timeLeft)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Details Row using Column for text below icon
                   Padding(
  padding: const EdgeInsets.symmetric(horizontal: 30.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: _buildDetailItemWithTextBelow(
          Icons.info, // Universal icon for detail one
          widget.raffleData['detailOne'] ?? 'Detail 1',
        ),
      ),
      Expanded(
        child: _buildDetailItemWithTextBelow(
          Icons.description, // Universal icon for detail two
          widget.raffleData['detailTwo'] ?? 'Detail 2',
        ),
      ),
      Expanded(
        child: _buildDetailItemWithTextBelow(
          Icons.more_horiz, // Universal icon for detail three
          widget.raffleData['detailThree'] ?? 'Detail 3',
        ),
      ),
    ],
  ),
),

                    const SizedBox(height: 30),

                    // Description Text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Text(
                        widget.raffleData['description'] ?? 'No description available.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Total and Enter Button
                    Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: \$${widget.raffleData['costPer'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PickSpotScreen(raffleData: widget.raffleData),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF15B29),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            ),
                            child: const Text(
                              'Enter Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  // Helper to create a timer box
  Widget _buildTimerBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: const Color(0xfff3f3f3),
      ),
      child: Text(
        time,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // Helper to create detail items with text below the icon
Widget _buildDetailItemWithTextBelow(IconData icon, String text) {
  return Column(
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 28, color: Colors.black),
      ),
      const SizedBox(height: 5),
      Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    ],
  );
}


}

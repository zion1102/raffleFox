import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:raffle_fox/blocs/raffle/raffle_bloc.dart';
import 'package:raffle_fox/blocs/guess/guess_bloc.dart';
import 'package:raffle_fox/pages/game_screen.dart';
import 'package:raffle_fox/widgets/BottomNavBar.dart';
import 'package:raffle_fox/widgets/ProfileAppBar.dart';

class RaffleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> raffleData;

  const RaffleDetailScreen({super.key, required this.raffleData});

  @override
  _RaffleDetailScreenState createState() => _RaffleDetailScreenState();
}

class _RaffleDetailScreenState extends State<RaffleDetailScreen> with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _timeLeft = const Duration();
  bool isLiked = false;
  bool isLoadingLike = false;
  late AnimationController _animationController;
  Color _heartOutlineColor = Colors.black; // Default heart outline color

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _checkIfLiked();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _determineHeartOutlineColor();
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startCountdown() {
  final expiryDate = widget.raffleData['expiryDate']; // Already normalized to DateTime
  DateTime now = DateTime.now();
  if (expiryDate.isAfter(now)) {
    _timeLeft = expiryDate.difference(now);

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
      print("Error: User or raffleId is null in _checkIfLiked");
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
      print("Error: User or raffleId is null in _toggleLike");
      return;
    }

    setState(() {
      isLoadingLike = true;
    });

    try {
      final likeRef = FirebaseFirestore.instance.collection('userLikes').doc('${user.uid}_$raffleId');
      final raffleRef = FirebaseFirestore.instance.collection('raffles').doc(raffleId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final raffleSnapshot = await transaction.get(raffleRef);

        if (!raffleSnapshot.exists) {
          throw Exception("Raffle not found");
        }

        if (isLiked) {
          transaction.delete(likeRef);
          transaction.update(raffleRef, {
            'likes': (raffleSnapshot['likes'] ?? 0) - 1,
          });
        } else {
          transaction.set(likeRef, {
            'raffleId': raffleId,
            'userId': user.uid,
            'timestamp': FieldValue.serverTimestamp(),
            'expiryDate': widget.raffleData['expiryDate'],
            'title': widget.raffleData['title'],
            'imageUrl': widget.raffleData['picture'],
          });
          transaction.update(raffleRef, {
            'likes': (raffleSnapshot['likes'] ?? 0) + 1,
          });
        }
      });

      setState(() {
        isLiked = !isLiked;
      });

      if (isLiked) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    } catch (e) {
      print("Error toggling like: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update like status")),
      );
    } finally {
      setState(() {
        isLoadingLike = false;
      });
    }
  }

  Future<void> _determineHeartOutlineColor() async {
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(widget.raffleData['picture']),
        size: const Size(100, 100), // Sample a smaller area for efficiency
      );

      final dominantColor = paletteGenerator.dominantColor?.color ?? Colors.black;

      setState(() {
        _heartOutlineColor = _isColorBright(dominantColor) ? Colors.black : Colors.white;
      });
    } catch (e) {
      print("Error determining heart outline color: $e");
      setState(() {
        _heartOutlineColor = Colors.black; // Default to black on failure
      });
    }
  }

  bool _isColorBright(Color color) {
    final brightness = (color.red * 299 + color.green * 587 + color.blue * 114) / 1000;
    return brightness > 128; // Bright if perceived brightness > 128
  }

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
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return BlocProvider(
      create: (context) => RaffleBloc(firestore: FirebaseFirestore.instance)
        ..add(LoadRaffleStatus(widget.raffleData['raffleId'], userId)),
      child: Scaffold(
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
                                onTap: isLoadingLike ? null : _toggleLike,
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: 1.0 + (_animationController.value * 0.2),
                                      child: Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: isLiked ? Colors.red : _heartOutlineColor,
                                        size: 40,
                                      ),
                                    );
                                  },
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

                      // Details Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildDetailItemWithTextBelow(
                                Icons.info,
                                widget.raffleData['detailOne'] ?? 'Detail 1',
                              ),
                            ),
                            Expanded(
                              child: _buildDetailItemWithTextBelow(
                                Icons.description,
                                widget.raffleData['detailTwo'] ?? 'Detail 2',
                              ),
                            ),
                            Expanded(
                              child: _buildDetailItemWithTextBelow(
                                Icons.more_horiz,
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
                                    builder: (_) => BlocProvider(
                                      create: (_) => GuessBloc(),
                                      child: PickSpotScreen(raffleData: widget.raffleData),
                                    ),
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
      ),
    );
  }

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

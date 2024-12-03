import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:raffle_fox/pages/raffle_detail.dart';
import 'package:raffle_fox/services/firebase_services.dart';
import 'package:raffle_fox/services/raffle_service.dart';

class MainBanner extends StatefulWidget {
  const MainBanner({super.key});

  @override
  _MainBannerState createState() => _MainBannerState();
}

class _MainBannerState extends State<MainBanner> {
  final FirebaseService _firebaseService = FirebaseService();
  final RaffleService _raffleService = RaffleService();
  Map<String, dynamic>? recentRaffle;

  @override
  void initState() {
    super.initState();
    _fetchRecentRaffle();
  }

  Future<void> _fetchRecentRaffle() async {
    try {
      Map<String, dynamic>? raffle = await _raffleService.fetchMostRecentRaffle();

      if (!mounted) return;

      setState(() {
        if (raffle != null) {
          // Ensure the 'expiryDate' is converted to DateTime if it's a Timestamp
          raffle['expiryDate'] = (raffle['expiryDate'] is Timestamp)
              ? (raffle['expiryDate'] as Timestamp).toDate()
              : raffle['expiryDate'];
          recentRaffle = raffle;
        } else {
          // Fallback if no raffles are available
          recentRaffle = {
            'title': 'No raffles available',
            'picture': 'https://via.placeholder.com/370x160.png?text=No+raffles+available',
            'expiryDate': DateTime.now().add(const Duration(days: 7)), // Placeholder expiry date
          };
        }
      });
    } catch (e) {
      print("Error fetching recent raffle: $e");
      if (mounted) {
        setState(() {
          recentRaffle = {
            'title': 'Error loading raffle',
            'picture': 'https://via.placeholder.com/370x160.png?text=Error',
            'expiryDate': DateTime.now(),
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = recentRaffle?['title'] ?? 'Loading...';
    final picture = recentRaffle?['picture'] as String? ??
        'https://via.placeholder.com/370x160.png?text=No+raffles+available';

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Container(
          width: 370,
          height: 220,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Stack(
            children: [
              // Background Image
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: 370,
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(picture),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Play Now Button
              Positioned(
                left: 10,
                top: 180,
                child: InkWell(
                  onTap: () {
                    if (recentRaffle != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RaffleDetailScreen(
                            raffleData: recentRaffle!,
                          ),
                        ),
                      );
                      print('Play Now button tapped');
                    }
                  },
                  child: Container(
                    width: 81,
                    height: 25,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFF9500),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      shadows: const [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Play Now',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Gibson',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Title
              Positioned(
                left: 22,
                top: 20,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Gibson',
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              // Footer Text
              const Positioned(
                right: 10,
                bottom: 10,
                child: Text(
                  'Guess the Spot to Win NOW!',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'Gotham',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

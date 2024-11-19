import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:raffle_fox/services/raffle_service.dart';
import 'package:raffle_fox/pages/raffle_detail.dart';
import 'package:raffle_fox/widgets/LatestRaffles.dart';


class MostPopular extends StatelessWidget {
  const MostPopular({super.key});

  Future<List<Map<String, dynamic>>> _fetchMostPopularRaffles() async {
    final raffleService = RaffleService();
    return await raffleService.getMostPopularRaffles();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchMostPopularRaffles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error loading popular raffles"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text(""));
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
                    'Most Popular',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF15B29),
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF202020),
                        ),
                      ),
                      const SizedBox(width: 5),
                      SvgPicture.asset(
                        'assets/images/Button.svg',
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: raffles.map((raffle) => buildMostPopularCard(context, raffle)).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build each "Most Popular" card
  Widget buildMostPopularCard(BuildContext context, Map<String, dynamic> raffle) {
    DateTime expiryDate = (raffle['expiryDate'] is Timestamp)
        ? (raffle['expiryDate'] as Timestamp).toDate()
        : DateTime.parse(raffle['expiryDate']);

    return GestureDetector(
      onTap: () {
        // Navigate to the raffle detail screen when the card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RaffleDetailScreen(raffleData: raffle),
          ),
        );
      },
      child: Container(
        width: 104,
        height: 160,
        margin: const EdgeInsets.only(right: 10),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with white border
            Container(
              width: 93,
              height: 103,
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.grey.shade300,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.network(
                  raffle['picture'] ?? 'https://via.placeholder.com/370x160.png/cccccc/ffffff?text=No+Image',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                ),
              ),
            ),
            // Countdown timer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CountdownTimer(expiryDate: expiryDate),
            ),
            // Like count and heart icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  Text(
                    raffle['likes'].toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

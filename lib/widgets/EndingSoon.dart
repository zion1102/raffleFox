import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:raffle_fox/services/raffle_service.dart';
import 'package:raffle_fox/pages/raffle_detail.dart';
import 'package:raffle_fox/widgets/LatestRaffles.dart';


class EndingSoon extends StatelessWidget {
  final Color titleColor;

  const EndingSoon({super.key, this.titleColor = const Color.fromARGB(255, 241, 91, 41)});

  Future<List<Map<String, dynamic>>> _fetchEndingSoonRaffles() async {
    final raffleService = RaffleService();
    return await raffleService.getEndingSoonRaffles();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchEndingSoonRaffles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Container(); // Return empty if there is an error
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(); // Return empty if there are no raffles
        }

        List<Map<String, dynamic>> raffles = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ending Soon',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const Icon(Icons.timer, color: Colors.black, size: 20),
                ],
              ),
              const SizedBox(height: 20),
              // Grid of "Ending Soon" raffles
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3, // Responsive grid count
                crossAxisSpacing: 10, // Reduced spacing for smaller cards
                mainAxisSpacing: 10, // Reduced spacing for smaller cards
                childAspectRatio: 0.8, // Adjusted aspect ratio for smaller cards
                children: raffles.map((raffle) => buildEndingSoonItem(context, raffle)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildEndingSoonItem(BuildContext context, Map<String, dynamic> raffle) {
    DateTime expiryDate = (raffle['expiryDate'] is Timestamp)
        ? (raffle['expiryDate'] as Timestamp).toDate()
        : DateTime.parse(raffle['expiryDate']);

    return GestureDetector(
      onTap: () {
        // Navigate to the raffle detail screen when tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RaffleDetailScreen(raffleData: raffle),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7), // Reduced border radius for smaller cards
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4, // Reduced blur radius for smaller cards
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.grey,
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
            ),
            const SizedBox(height: 6), // Reduced spacing for smaller cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0), // Reduced padding for smaller cards
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    raffle['title'] ?? 'No title',
                    style: const TextStyle(
                      fontSize: 13, // Reduced font size for smaller cards
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  CountdownTimer(expiryDate: expiryDate),
                ],
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing for smaller cards
          ],
        ),
      ),
    );
  }
}

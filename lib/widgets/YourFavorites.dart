import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:raffle_fox/pages/raffle_detail.dart';
import 'package:raffle_fox/services/firebase_services.dart';
import 'package:raffle_fox/widgets/TopRaffles.dart';

class YourFavorites extends StatefulWidget {
  const YourFavorites({super.key});

  @override
  _YourFavoritesState createState() => _YourFavoritesState();
}

class _YourFavoritesState extends State<YourFavorites> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> recentLikedRaffles = [];
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchRecentLikedRaffles();
  }

  Future<void> _fetchRecentLikedRaffles() async {
    try {
      List<Map<String, dynamic>> likedRaffles = await _firebaseService.getRecentLikedRaffles();
      setState(() {
        recentLikedRaffles = likedRaffles;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching liked raffles: $e";
        isLoading = false;
      });
      print(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    if (recentLikedRaffles.isEmpty) {
      return const Center(child: Text("You haven't liked any raffles yet."));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Favorites',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF15B29),
                ),
              ),
              SvgPicture.asset(
                'assets/images/star.svg',
                width: 19,
                height: 18.3,
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
              childAspectRatio: 1 / 1.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: recentLikedRaffles.length,
            itemBuilder: (context, index) {
              final raffle = recentLikedRaffles[index];
              final expiryDate = raffle['expiryDate'] is Timestamp
                  ? (raffle['expiryDate'] as Timestamp).toDate()
                  : raffle['expiryDate'];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RaffleDetailScreen(
                        raffleData: {
                          ...raffle,
                          'expiryDate': expiryDate,
                        },
                      ),
                    ),
                  );
                },
                child: buildFavoriteCard(raffle, expiryDate),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildFavoriteCard(Map<String, dynamic> raffle, DateTime expiryDate) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.network(
              raffle['picture'] ?? 'https://via.placeholder.com/370x160.png/cccccc/ffffff?text=No+Image',
              fit: BoxFit.cover,
              width: double.infinity,
              height: MediaQuery.of(context).size.width < 600 ? 140 : 160,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            raffle['title'] ?? "Raffle",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        CountdownTimer(expiryDate: expiryDate),
        const SizedBox(height: 2),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            "Play Now",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF15B29),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

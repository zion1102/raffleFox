import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raffle_fox/pages/raffle_detail.dart';
import 'package:raffle_fox/pages/seeAllPage.dart';
import 'package:raffle_fox/widgets/TopRaffles.dart';

class LatestRaffles extends StatelessWidget {
  const LatestRaffles({super.key});

  Future<List<Map<String, dynamic>>> fetchLatestRaffles() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('raffles')
        .where('expiryDate', isGreaterThan: Timestamp.now())
        .orderBy('expiryDate', descending: false)
        .limit(6)
        .get();

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
          return Container();
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeeAllPage(
                            pageTitle: 'Latest Raffles',
                            rafflesFuture: fetchLatestRaffles(),
                            sortType: 'latest',
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        const Text(
                          "See All",
                          style: TextStyle(
                            color: Color(0xFF202020),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SvgPicture.asset(
                          'assets/images/Button.svg',
                          width: 16,
                          height: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: raffles.map((raffle) => buildRaffleItem(context, raffle)).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildRaffleItem(BuildContext context, Map<String, dynamic> raffleData) {
    final expiryDate = raffleData['expiryDate'] is Timestamp
        ? (raffleData['expiryDate'] as Timestamp).toDate()
        : raffleData['expiryDate'];

    return Padding(
      padding: const EdgeInsets.only(right: 10.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RaffleDetailScreen(
                    raffleData: {
                      ...raffleData,
                      'expiryDate': expiryDate,
                    },
                  ),
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
                      image: NetworkImage(raffleData['picture'] ?? 'https://via.placeholder.com/370x160.png/cccccc/ffffff?text=No+raffles+available'),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RaffleDetailScreen(
                          raffleData: {
                            ...raffleData,
                            'expiryDate': expiryDate,
                          },
                        ),
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

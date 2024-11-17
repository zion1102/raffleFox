import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:raffle_fox/services/firebase_services.dart';
import 'package:raffle_fox/services/raffle_service.dart';
import 'package:raffle_fox/services/raffle_ticket_service.dart';
import 'package:raffle_fox/widgets/RaffleTicket.dart';

class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  _MyActivityScreenState createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final RaffleService _raffleService = RaffleService();
  final RaffleTicketService _raffleTicketService = RaffleTicketService();

  List<Map<String, dynamic>> likedRaffles = [];
  List<Map<String, dynamic>> boughtTickets = [];
  List<Map<String, dynamic>> cartTickets = [];
  List<Map<String, dynamic>> topUps = [];
  List<Map<String, dynamic>> endingSoonRaffles = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchActivityData();
  }

Future<void> _fetchActivityData() async {
  final userDetails = await _firebaseService.getUserDetails();
  if (userDetails != null) {
    final userId = userDetails['uid'];
    print("Testing bought tickets fetch for userId: $userId");

    // Fetch liked raffles
    likedRaffles = await _raffleService.getLikedRaffles(userId);

    // Fetch bought tickets and ensure critical fields are populated
    boughtTickets = await _raffleTicketService.getRaffleTicketsForUser(userId);
    print("Total bought tickets fetched: ${boughtTickets.length}");

    // Initialize Firestore instance for additional data fetch
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Log each bought ticket for debugging
    for (var ticket in boughtTickets) {
      print("Fetched ticket: ${ticket['raffleId']} - Title: ${ticket['title']} - Expiry: ${ticket['expiryDate']}");
      
      // Check if title or expiryDate is missing, and fetch from raffles collection if necessary
      if (ticket['title'] == null || ticket['expiryDate'] == null) {
        DocumentSnapshot raffleDoc = await firestore.collection('raffles').doc(ticket['raffleId']).get();
        if (raffleDoc.exists) {
          var raffleData = raffleDoc.data() as Map<String, dynamic>;
          ticket['title'] ??= raffleData['title'];
          ticket['expiryDate'] ??= raffleData['expiryDate'] is Timestamp
              ? (raffleData['expiryDate'] as Timestamp).toDate()
              : raffleData['expiryDate'];
        }
      }
    }

    // Fetch tickets in cart
    cartTickets = await _raffleService.getCartTickets(userId);

    // Fetch top-ups
    topUps = await _firebaseService.getUserTopUps(userId);

    // Fetch relevant ending soon raffles
    endingSoonRaffles = await _raffleService.getUserRelevantEndingSoonRaffles(userId);
  }

  setState(() {
    loading = false;
  });
}

  Widget _buildActivitySection(String title, List<Map<String, dynamic>> items) {
    print("Building section for $title with ${items.length} items");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        items.isNotEmpty
            ? Column(
                children: items.map((item) {
                  String? raffleId = item['raffleId'] as String?;
                  String? raffleTitle = item['title'] as String?;
                  DateTime? expiryDate = (item['expiryDate'] is Timestamp)
                      ? (item['expiryDate'] as Timestamp).toDate()
                      : item['expiryDate'];
                  int guesses = item['guessCount'] ?? 0;
                  double totalPrice = item['totalPrice'] ?? 0.0;

                  if (raffleId == null || raffleTitle == null || expiryDate == null) {
                    print("Warning: Missing data in item. "
                          "raffleId: $raffleId, title: $raffleTitle, expiryDate: $expiryDate");
                    return const SizedBox(); // Skip this item if critical fields are null
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: RaffleTicket(
                      raffleId: raffleId,
                      expiryDate: expiryDate,
                      title: raffleTitle,
                      guesses: guesses,
                      totalPrice: totalPrice,
                    ),
                  );
                }).toList(),
              )
            : const Text("No activity to show."),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Activity"),
        backgroundColor: const Color(0xFFFF5F00), // Matches the app's color scheme
      ),
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    _buildActivitySection("Liked Raffles", likedRaffles),
                    const SizedBox(height: 20),
                    _buildActivitySection("Tickets Bought", boughtTickets),
                    const SizedBox(height: 20),
                    _buildActivitySection("Tickets in Cart", cartTickets),
                    const SizedBox(height: 20),
                    _buildActivitySection("Top-Ups", topUps),
                    const SizedBox(height: 20),
                    _buildActivitySection("Ending Soon", endingSoonRaffles),
                  ],
                ),
              ),
      ),
    );
  }
}

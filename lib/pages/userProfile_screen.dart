import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:raffle_fox/pages/login_screen.dart';
import 'package:raffle_fox/pages/topup.dart';

import 'package:raffle_fox/services/firebase_services.dart';
import 'package:raffle_fox/services/raffle_service.dart';
import 'package:raffle_fox/services/raffle_ticket_service.dart';
import 'package:raffle_fox/widgets/AnnouncementSection.dart';
import 'package:raffle_fox/widgets/BottomNavBar.dart';
import 'package:raffle_fox/widgets/CreatorBottomNavBar.dart';
import 'package:raffle_fox/widgets/RaffleTicket.dart';
import 'dart:async';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final RaffleTicketService _raffleTicketService = RaffleTicketService();
  final RaffleService _raffleService = RaffleService();

  Map<String, dynamic>? userDetails;
  List<Map<String, dynamic>> displayedRaffles = [];
  List<Map<String, dynamic>> likedRaffles = [];
  List<Map<String, dynamic>> boughtTickets = [];
  List<Map<String, dynamic>> cartTickets = [];
  List<Map<String, dynamic>> topUps = [];
  List<Map<String, dynamic>> endingSoonRaffles = [];
  bool isCreator = false;
  bool loading = true;
  bool rafflesFetched = false;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  @override
  void dispose() {
    for (var timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      loading = true;
    });
    Map<String, dynamic>? details = await _firebaseService.getUserDetails();
    if (mounted) {
      setState(() {
        userDetails = details;
        isCreator = userDetails != null && userDetails!['userType'] == 'creator';
        loading = false;
      });
    }

    if (userDetails != null) {
      await _fetchActivityData();
    }
  }

  Future<void> _fetchActivityData() async {
    setState(() {
      loading = true;
    });
    final userDetails = await _firebaseService.getUserDetails();
    if (userDetails != null) {
      final userId = userDetails['uid'];
      print("Fetching activity data for userId: $userId");

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

    if (mounted) {
      setState(() {
        rafflesFetched = true;
        loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _firebaseService.logoutUser();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _deleteAccount() async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      await _firebaseService.deleteUserAccount();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
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
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: ListView(
                    children: [
                      const Text(
                        "My Raffles",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage: userDetails != null && userDetails!['profilePicture'] != ''
                                    ? NetworkImage(userDetails!['profilePicture'])
                                    : const NetworkImage("https://via.placeholder.com/150"),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5F00),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Text(
                                    "My Activity",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
  children: [
    IconButton(
      icon: const Icon(Icons.notifications_outlined, color: Color(0xFFFF5F00)),
      onPressed: () {},
    ),
    IconButton(
      icon: const Icon(Icons.attach_money, color: Color(0xFFFF5F00)),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TopUpPage()),
        );
      },
    ),
    PopupMenuButton<String>(
      icon: const Icon(Icons.settings_outlined, color: Color(0xFFFF5F00)),
      onSelected: (value) {
        if (value == 'logout') {
          _logout();
        } else if (value == 'editProfile') {
        } else if (value == 'deleteAccount') {
          _deleteAccount();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'editProfile',
          child: Text('Edit Profile'),
        ),
        const PopupMenuItem<String>(
          value: 'deleteAccount',
          child: Text('Delete Account'),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Text('Logout'),
        ),
      ],
    ),
  ],
),

                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userDetails != null ? "Hello, ${userDetails!['name']}!" : "Hello!",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnnouncementSection(),
                      const SizedBox(height: 20),
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
        bottomNavigationBar: loading
            ? null
            : isCreator
                ? const CreatorBottomNavBar(selectedIndex: 0)
                : const BottomNavBar(),
      ),
    );
  }
}

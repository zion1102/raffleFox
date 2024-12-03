import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raffle_fox/blocs/auth/auth_bloc.dart';
import 'package:raffle_fox/pages/login_screen.dart';
import 'package:raffle_fox/pages/topup.dart';
import 'package:raffle_fox/pages/raffle_detail.dart';
import 'package:raffle_fox/services/firebase_services.dart';
import 'package:raffle_fox/services/raffle_service.dart';
import 'package:raffle_fox/services/raffle_ticket_service.dart';
import 'package:raffle_fox/widgets/BottomNavBar.dart';
import 'package:raffle_fox/widgets/CreatorBottomNavBar.dart';
import 'package:raffle_fox/widgets/RaffleTicket.dart';

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
  List<Map<String, dynamic>> likedRaffles = [];
  List<Map<String, dynamic>> boughtTickets = [];
  List<Map<String, dynamic>> cartTickets = [];
  List<Map<String, dynamic>> endingSoonRaffles = [];
  int credits = 0;
  bool isCreator = false;
  bool loading = true;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _initializeUserData() async {
    setState(() => loading = true);

    try {
      userDetails = await _firebaseService.getUserDetails();
      if (userDetails != null) {
        isCreator = userDetails!['userType'] == 'creator';
        credits = userDetails!['credits'] ?? 0;
        final userId = userDetails!['uid'];

        final results = await Future.wait([
          _raffleService.getLikedRaffles(userId),
          _raffleTicketService.getRaffleTicketsForUser(userId),
          _raffleService.getCartTickets(userId),
          _raffleService.getUserRelevantEndingSoonRaffles(userId),
        ]);

        likedRaffles = _filterAndGroupRaffles(results[0]);
        boughtTickets = _filterAndGroupRaffles(results[1]);
        cartTickets = _filterAndGroupRaffles(results[2]);
        endingSoonRaffles = _filterAndGroupRaffles(results[3]);
      }
    } catch (e) {
      print("Error initializing user data: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  List<Map<String, dynamic>> _filterAndGroupRaffles(List<Map<String, dynamic>> raffles) {
    final now = DateTime.now();
    final groupedRaffles = <String, Map<String, dynamic>>{};

    for (var raffle in raffles) {
      final expiryDate = raffle['expiryDate'] is Timestamp
          ? (raffle['expiryDate'] as Timestamp).toDate()
          : raffle['expiryDate'];

      if (expiryDate != null && expiryDate.isAfter(now)) {
        final raffleId = raffle['raffleId'];
        if (groupedRaffles.containsKey(raffleId)) {
          groupedRaffles[raffleId]!['guessCount'] =
              (groupedRaffles[raffleId]!['guessCount'] ?? 0) + 1;
        } else {
          groupedRaffles[raffleId] = {
            ...raffle,
            'guessCount': 1,
          };
        }
      }
    }

    return groupedRaffles.values.toList();
  }

  String _formatCountdown(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);

    if (difference.isNegative) {
      return "Expired";
    } else {
      final hours = difference.inHours.remainder(24);
      final minutes = difference.inMinutes.remainder(60);
      final seconds = difference.inSeconds.remainder(60);

      return "${difference.inDays}d ${hours}h ${minutes}m ${seconds}s";
    }
  }

  Widget _buildCreditsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Current Credits",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "\$${credits.toStringAsFixed(2)}", // Display credits formatted as currency
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF5F00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaffleCardWithImage(Map<String, dynamic> raffleData) {
    final expiryDate = raffleData['expiryDate'] is Timestamp
        ? (raffleData['expiryDate'] as Timestamp).toDate()
        : raffleData['expiryDate'];

    return GestureDetector(
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
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              child: Image.network(
                raffleData['picture'] ?? 'https://via.placeholder.com/300',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    raffleData['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    expiryDate != null
                        ? "Valid Until: ${expiryDate.toLocal().toString().split(' ')[0]}"
                        : "No expiry date",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        expiryDate != null
                            ? _formatCountdown(expiryDate)
                            : "No expiry",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySectionWithImages(
      String title, List<Map<String, dynamic>> items) {
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
                children: items
                    .map((item) => _buildRaffleCardWithImage(item))
                    .toList(),
              )
            : const Text("No activity to show."),
      ],
    );
  }

  Widget _buildActivitySection(String title, List<Map<String, dynamic>> items,
      {bool useRaffleTicket = false}) {
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
                  return useRaffleTicket
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: RaffleTicket(
                            raffleId: item['raffleId'],
                            expiryDate: item['expiryDate'] is Timestamp
                                ? (item['expiryDate'] as Timestamp).toDate()
                                : item['expiryDate'],
                            title: item['raffleTitle'] ?? 'No Title',
                            guesses: item['guessCount'] ?? 0,
                            totalPrice: item['totalPrice'] ?? 0.0,
                          ),
                        )
                      : const SizedBox();
                }).toList(),
              )
            : const Text("No activity to show."),
      ],
    );
  }

  Future<void> _logout() async {
    await _firebaseService.logoutUser();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (_) => AuthBloc(FirebaseService()),
            child: const LoginScreen(),
          ),
        ),
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
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (_) => AuthBloc(FirebaseService()),
              child: const LoginScreen(),
            ),
          ),
        );
      }
    }
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
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                  backgroundImage: userDetails != null &&
                                          userDetails!['profilePicture'] != ''
                                      ? NetworkImage(userDetails!['profilePicture'])
                                      : const NetworkImage("https://via.placeholder.com/150"),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
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
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Color(0xFFFF5F00),
                                  ),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.attach_money,
                                    color: Color(0xFFFF5F00),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const TopUpPage()),
                                    );
                                  },
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.settings_outlined,
                                    color: Color(0xFFFF5F00),
                                  ),
                                  onSelected: (value) {
                                    if (value == 'logout') {
                                      _logout();
                                    } else if (value == 'deleteAccount') {
                                      _deleteAccount();
                                    }
                                  },
                                  itemBuilder: (context) => [
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
                          userDetails != null
                              ? "Hello, ${userDetails!['name']}!"
                              : "Hello!",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildCreditsSection(),
                        const SizedBox(height: 20),
                        _buildActivitySectionWithImages(
                            "Liked Raffles", likedRaffles),
                        const SizedBox(height: 20),
                        _buildActivitySection("Tickets Bought", boughtTickets,
                            useRaffleTicket: true),
                        const SizedBox(height: 20),
                        _buildActivitySection("Tickets in Cart", cartTickets,
                            useRaffleTicket: true),
                        const SizedBox(height: 20),
                        _buildActivitySectionWithImages(
                            "Ending Soon", endingSoonRaffles),
                      ],
                    ),
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

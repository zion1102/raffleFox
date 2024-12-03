import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:raffle_fox/pages/raffle_detail.dart';

class SeeAllPage extends StatefulWidget {
  final String pageTitle;
  final Future<List<Map<String, dynamic>>> rafflesFuture;
  final String sortType;

  const SeeAllPage({
    Key? key,
    required this.pageTitle,
    required this.rafflesFuture,
    required this.sortType,
  }) : super(key: key);

  @override
  _SeeAllPageState createState() => _SeeAllPageState();
}

class _SeeAllPageState extends State<SeeAllPage> {
  late Future<List<Map<String, dynamic>>> rafflesFuture;
  List<Map<String, dynamic>>? raffles;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    rafflesFuture = _sortRaffles(widget.rafflesFuture, widget.sortType);
  }

  Future<List<Map<String, dynamic>>> _sortRaffles(
      Future<List<Map<String, dynamic>>> futureRaffles, String sortType) async {
    List<Map<String, dynamic>> raffles = await futureRaffles;

    if (sortType == 'latest') {
      raffles.sort((a, b) {
        DateTime dateA = a['createdAt'] is Timestamp
            ? (a['createdAt'] as Timestamp).toDate()
            : DateTime.parse(a['createdAt']);
        DateTime dateB = b['createdAt'] is Timestamp
            ? (b['createdAt'] as Timestamp).toDate()
            : DateTime.parse(b['createdAt']);
        return dateB.compareTo(dateA);
      });
    } else if (sortType == 'endingSoon') {
      raffles.sort((a, b) {
        DateTime dateA = a['expiryDate'] is Timestamp
            ? (a['expiryDate'] as Timestamp).toDate()
            : DateTime.parse(a['expiryDate']);
        DateTime dateB = b['expiryDate'] is Timestamp
            ? (b['expiryDate'] as Timestamp).toDate()
            : DateTime.parse(b['expiryDate']);
        return dateA.compareTo(dateB);
      });
    } else if (sortType == 'mostPopular') {
      raffles.sort((a, b) => (b['likes'] ?? 0).compareTo(a['likes'] ?? 0));
    }

    return raffles;
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  List<Map<String, dynamic>> _filterRaffles(List<Map<String, dynamic>> raffles) {
    if (searchQuery.isEmpty) return raffles;
    return raffles.where((raffle) {
      final title = raffle['title']?.toLowerCase() ?? "";
      return title.contains(searchQuery);
    }).toList();
  }

  String _formatCountdown(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (days > 0) {
      return "$days days $hours:$minutes:$seconds";
    } else {
      return "$hours:$minutes:$seconds";
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pageTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF202020),
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFFF5F00)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5F00)),
                hintText: "Search raffles...",
                hintStyle: const TextStyle(
                  color: Color(0xFFB0B0B0),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Color(0xFFFF5F00)),
                ),
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: rafflesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text("Error loading raffles."));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No raffles found."));
                }

                raffles = _filterRaffles(snapshot.data!);

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenWidth < 600 ? 2 : 3,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: raffles!.length,
                  itemBuilder: (context, index) {
                    final raffle = raffles![index];

                    // Ensure expiryDate is converted to DateTime
                    final expiryDate = raffle['expiryDate'] is Timestamp
                        ? (raffle['expiryDate'] as Timestamp).toDate()
                        : DateTime.tryParse(raffle['expiryDate']) ?? DateTime.now();

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RaffleDetailScreen(
                              raffleData: {
                                ...raffle,
                                'expiryDate': expiryDate, // Pass normalized expiryDate
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12.0),
                                topRight: Radius.circular(12.0),
                              ),
                              child: Image.network(
                                raffle['picture'] ??
                                    'https://via.placeholder.com/150',
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error, size: 50),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    raffle['title'] ?? "No Title",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF202020),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  StreamBuilder<DateTime>(
                                    stream: Stream.periodic(
                                        const Duration(seconds: 1),
                                        (_) => DateTime.now()),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const SizedBox();
                                      }
                                      final now = snapshot.data!;
                                      final remaining = expiryDate.difference(now);
                                      final countdownText = remaining.isNegative
                                          ? "Expired"
                                          : _formatCountdown(remaining);
                                      return Text(
                                        countdownText,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFFF5F00),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

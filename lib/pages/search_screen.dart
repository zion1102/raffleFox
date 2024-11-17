import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:raffle_fox/pages/raffle_detail.dart';
import 'package:raffle_fox/widgets/BottomNavBar.dart';
import 'package:raffle_fox/widgets/EndingSoon.dart';
import 'package:fuzzy/fuzzy.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Box? searchBox;
  List<String> searchHistory = [];
  final TextEditingController _searchController = TextEditingController();
  bool showResults = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    openSearchBox();
    _searchController.addListener(_onSearchTextChanged);
  }

  Future<void> openSearchBox() async {
    searchBox = await Hive.openBox('searchHistory');
    loadSearchHistory();
  }

  void loadSearchHistory() {
    if (searchBox != null) {
      setState(() {
        searchHistory = List<String>.from(searchBox!.get('history', defaultValue: <String>[]));
      });
    }
  }

  void addSearch(String searchTerm) {
    if (searchBox != null && !searchHistory.contains(searchTerm)) {
      searchHistory.insert(0, searchTerm);
      if (searchHistory.length > 10) {
        searchHistory = searchHistory.sublist(0, 10);
      }
      searchBox!.put('history', searchHistory);
      setState(() {});
    }
  }

  void clearHistory() {
    if (searchBox != null) {
      searchBox!.put('history', []);
      loadSearchHistory();
    }
  }

  void _onSearchTextChanged() {
    setState(() {
      showResults = _searchController.text.isNotEmpty;
    });
    if (showResults) {
      _performSearch(_searchController.text);
    }
  }

Future<void> _performSearch(String query) async {
  if (query.isEmpty) {
    setState(() {
      _searchResults.clear();
    });
    return;
  }

  final lowercaseQuery = query.toLowerCase();

  // Retrieve all raffles from Firestore and filter out expired ones
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('raffles')
      .where('expiryDate', isGreaterThan: Timestamp.now()) // Filter out expired raffles
      .get();

  List<Map<String, dynamic>> allRaffles = snapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>)
      .toList();

  // Extract titles for fuzzy search
  List<String> titles = allRaffles.map((raffle) => raffle['title'] as String).toList();

  // Initialize Fuzzy search
  final fuse = Fuzzy(
    titles,
    options: FuzzyOptions(
      findAllMatches: true,
      threshold: 0.5, // Adjust threshold as needed
    ),
  );

  // Perform fuzzy search
  final result = fuse.search(query);

  // Map results back to raffle data
  List<Map<String, dynamic>> results = result.map((res) {
    return allRaffles.firstWhere((raffle) => raffle['title'] == res.item);
  }).toList();

  setState(() {
    _searchResults = results;
  });
}

void searchForTerm(String term) {
    _searchController.text = term;
    addSearch(term);
    setState(() {
      showResults = true;
    });
    _performSearch(term);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "Search",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search for raffles...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: showResults ? _buildResultsPage() : _buildDefaultPage(),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }

  Widget _buildDefaultPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Search history",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: clearHistory,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: searchHistory.take(10).map((term) {
              return GestureDetector(
                onTap: () => searchForTerm(term),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xfff4f4f4),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    term,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 50),
          const EndingSoon(),
        ],
      ),
    );
  }

  Widget _buildResultsPage() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text("No results found."));
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.6,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        var raffle = _searchResults[index];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RaffleDetailScreen(raffleData: raffle),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                  image: raffle['picture'] != null
                      ? DecorationImage(
                          image: NetworkImage(raffle['picture']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                raffle['title'] ?? '',
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "\$${raffle['costPer']}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.favorite_border, color: Colors.grey),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

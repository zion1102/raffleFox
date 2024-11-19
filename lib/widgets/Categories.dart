import 'package:flutter/material.dart';
import 'package:raffle_fox/services/raffle_service.dart';

class CategoriesSection extends StatefulWidget {
  const CategoriesSection({super.key});

  @override
  _CategoriesSectionState createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  final RaffleService _raffleService = RaffleService();
  late Future<Map<String, List<Map<String, dynamic>>>> _rafflesByCategoryFuture;

  @override
  void initState() {
    super.initState();
    _rafflesByCategoryFuture = _raffleService.getRafflesByCategories([
      'Lifestyle',
      'Entertainment',
      'Devices',
      'Electronics',
      'Style',
      'Beauty & Grooming',
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: _rafflesByCategoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading categories'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text(''));
        }

        Map<String, List<Map<String, dynamic>>> rafflesByCategory = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  color: Color(0xFFF15B29),
                  fontSize: 21,
                  fontFamily: 'Gibson',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 20,
                childAspectRatio: 162.04 / 205,
                children: rafflesByCategory.entries.map((entry) {
                  return buildCategoryCard(entry.key, entry.value);
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildCategoryCard(String category, List<Map<String, dynamic>> raffles) {
    return Container(
      width: 162.04,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GridView.builder(
                    itemCount: raffles.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemBuilder: (context, index) {
                      return buildImageBox(raffles[index]['picture']);
                    },
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  category,
                  style: const TextStyle(
                    color: Color(0xFF202020),
                    fontSize: 14,
                    fontFamily: 'Gotham',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              width: 37.32,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFF15B29),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${raffles.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'Gibson',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildImageBox(String imageUrl) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

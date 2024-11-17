import 'package:flutter/material.dart';
import 'package:raffle_fox/pages/search_screen.dart';

class SearchBarElement extends StatelessWidget {
  const SearchBarElement({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchScreen()),
          );
        },
        child: Container(
          width: 370,
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.search, color: Colors.grey),
              ),
              Expanded(
                child: Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.camera_alt, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

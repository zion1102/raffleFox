import 'package:flutter/material.dart';

class CustomProgressBar extends StatelessWidget {
  final double progress; // Takes in a progress value between 0 and 1

  const CustomProgressBar({super.key, required this.progress, required Color progressColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none, // Allow the circles to overflow if necessary
      children: [
        Container(
          width: double.infinity,
          height: 16, // Increase the height slightly to avoid clipping
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), // Rounded edges for the bar
            color: const Color.fromARGB(142, 208, 207, 207),
          ),
        ),
        Positioned(
          left: 0,
          child: Container(
            width: MediaQuery.of(context).size.width * progress, // Dynamic width for progress
            height: 10, // Smaller inner bar height to make it look rounder
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), // Rounded progress bar
              color: const Color(0xFFFF5F00), // Orange color for the progress
            ),
          ),
        ),
        // Ellipses overlayed at the start, middle, and end
        const Positioned(
          left: -14, // Correct positioning to ensure it's not cut off
          child: CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white,
            child: Icon(Icons.circle, color: Color(0xFFFF5F00), size: 24),
          ),
        ),
        Positioned(
          left: MediaQuery.of(context).size.width * progress - 14,
          child: const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white,
            child: Icon(Icons.circle, color: Color.fromARGB(255, 248, 194, 118), size: 24),
          ),
        ),
        const Positioned(
          right: -14, // Correct positioning to ensure it's not cut off
          child: CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white,
            child: Icon(Icons.circle, color: Color(0xfff3f3f3), size: 24), // Greyed out for unfinished part
          ),
        ),
      ],
    );
  }
}

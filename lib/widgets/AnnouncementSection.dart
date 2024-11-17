import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AnnouncementSection extends StatelessWidget {
  const AnnouncementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Set the width to be responsive to screen size
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      border: Border.all(width: 0.8, color: const Color(0xffff5f00),),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text section with Expanded to prevent overflow
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Announcement Title
                  Text(
                    "Announcement",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black, // Black text
                    ),
                  ),
                  SizedBox(height: 4), // Space between title and description
                  // Announcement Description
                  Text(
                    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas hendrerit luctus",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54, // Slightly lighter black
                    ),
                    overflow: TextOverflow.ellipsis, // Add ellipsis to prevent overflow
                    maxLines: 2, // Limit to 2 lines
                  ),
                ],
              ),
            ),
          ),
          // Orange Arrow Button with flexible size
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SvgPicture.asset(
              "assets/images/Button.svg", // Path to the arrow image
              width: 20, // Adjust size as needed
              height: 20, // Adjust size as needed
              fit: BoxFit.contain, // Prevents overflow
            ),
          ),
        ],
      ),
    );
  }
}

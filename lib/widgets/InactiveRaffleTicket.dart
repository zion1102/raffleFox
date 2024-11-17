import 'package:flutter/material.dart';

class InactiveRaffleTicket extends StatelessWidget {
  const InactiveRaffleTicket({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 336,
      height: 120, // Adjusted height for alignment
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: Colors.white,
        border: Border.all(color: Colors.grey, width: 2), // Grey border
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Add padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car Raffle Title
                Text(
                  "Car Raffle #1234",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey, // Grey color for inactive
                  ),
                ),
                SizedBox(height: 8),

                // Prize Description
                Text(
                  "Win Ford Ranger 4x4",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),

                // Guesses
                Text(
                  "10 Guesses",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Ended Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7E8EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Ended",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // View Button
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF95989A), // Grey color for inactive
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    "View",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ActiveRaffleTicket extends StatelessWidget {
  const ActiveRaffleTicket({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 336,
      height: 120, // Increased height for better alignment
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFF5F00), width: 2), // Orange border
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Add padding inside the container
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
                    color: Color(0xFFFF5F00), // Orange color
                  ),
                ),
                SizedBox(height: 8), // Space between title and description

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
                // Expiry Date Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Valid Until 11.16.24",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 8), // Space between status and button

                // View Button
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5F00),
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

import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';

class RaffleTicket extends StatelessWidget {
  final double indentHeight;
  final String raffleId;
  final DateTime expiryDate;
  final String title;
  final int guesses;
  final double totalPrice;

  const RaffleTicket({
    super.key,
    required this.raffleId,
    required this.expiryDate,
    required this.title,
    required this.guesses,
    required this.totalPrice,
    this.indentHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double ticketWidth = screenWidth * 0.92;
    double ticketHeight = screenWidth * 0.4; // Adjusted for responsiveness
    double indentWidth = ticketWidth * 0.07;
    double indentPosition = (ticketHeight - indentHeight) / 2;
    double fontScale = screenWidth * 0.04;
    bool isExpired = expiryDate.isBefore(DateTime.now());

    return Stack(
      children: [
        // Main Ticket Body
        Container(
          width: ticketWidth,
          height: ticketHeight,
          decoration: BoxDecoration(
            color: isExpired
                ? const Color.fromARGB(255, 242, 242, 242)
                : const Color.fromARGB(255, 255, 255, 255),
            border: Border.all(
              color: isExpired
                  ? const Color.fromARGB(255, 200, 200, 200)
                  : const Color(0xffff5f00),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        // Left Circular Cutout
        Positioned(
          left: -indentWidth / 2,
          top: indentPosition,
          child: Container(
            width: indentWidth,
            height: indentHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              border: Border.all(
                color: isExpired
                    ? const Color.fromARGB(255, 200, 200, 200)
                    : const Color(0xffff5f00),
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Right Circular Cutout
        Positioned(
          right: -indentWidth / 2,
          top: indentPosition,
          child: Container(
            width: indentWidth,
            height: indentHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              border: Border.all(
                color: isExpired
                    ? const Color.fromARGB(255, 200, 200, 200)
                    : const Color(0xffff5f00),
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Raffle ID
        Positioned(
          top: 10, // Moved up slightly
          left: 20,
          right: 100, // Allow room for the expiry date
          child: Text(
            "#$raffleId",
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontScale * 0.8,
              fontWeight: FontWeight.bold,
              color: isExpired
                  ? const Color.fromARGB(255, 200, 200, 200)
                  : const Color(0xffff5f00),
            ),
          ),
        ),
        // Expiry Date
        Positioned(
          top: 10, // Moved up slightly
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isExpired
                  ? const Color.fromARGB(255, 255, 215, 215)
                  : const Color(0xfffff4e6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isExpired
                  ? "Expired on ${expiryDate.toLocal().toString().split(' ')[0]}"
                  : "Valid Until ${expiryDate.toLocal().toString().split(' ')[0]}",
              style: TextStyle(
                fontSize: fontScale * 0.8,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF000000),
              ),
            ),
          ),
        ),
        // Title
        Positioned(
          top: 40, // Kept the title at the same position for consistency
          left: 20,
          right: 100,
          child: Text(
            title,
            style: TextStyle(
              fontSize: fontScale * 1.1,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF000000),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Dotted Line
        Positioned(
          top: ticketHeight * 0.5,
          left: 20,
          right: 20,
          child: Dash(
            length: ticketWidth - 44,
            dashLength: 6,
            dashColor: isExpired
                ? const Color.fromARGB(255, 200, 200, 200)
                : const Color(0xffff5f00),
          ),
        ),
        // Ticket Info
        Positioned(
          bottom: 20, // Adjusted for proper spacing
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$guesses ${guesses == 1 ? 'Ticket' : 'Tickets'}",
                style: TextStyle(
                  fontSize: fontScale * 0.9,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Total: \$${totalPrice.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: fontScale * 0.9,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF000000),
                ),
              ),
            ],
          ),
        ),
        // View Button
        Positioned(
          right: 20,
          bottom: 20, // Adjusted for proper spacing
          child: Container(
            width: ticketWidth * 0.22,
            height: ticketHeight * 0.22,
            decoration: BoxDecoration(
              color: isExpired
                  ? const Color.fromARGB(255, 200, 200, 200)
                  : const Color(0xffff5f00),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: const Text(
              "View",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

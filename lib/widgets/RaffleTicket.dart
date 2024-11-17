import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RaffleTicket extends StatefulWidget {
  final double indentHeight;
  final String raffleId;
  final DateTime expiryDate;
  final String title;
  final int guesses;
  final double totalPrice; // New field for total price

  const RaffleTicket({super.key, 
    required this.raffleId,
    required this.expiryDate,
    required this.title,
    required this.guesses,
    required this.totalPrice, // Include totalPrice in the constructor
    this.indentHeight = 80,
  });

  @override
  _RaffleTicketState createState() => _RaffleTicketState();
}

class _RaffleTicketState extends State<RaffleTicket> {
  bool isCreator = false;
  int totalTicketsBought = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserTypeAndTickets();
    _debugRaffleTicketInfo();
  }

  void _debugRaffleTicketInfo() {
    print("RaffleTicket created with the following data:");
    print("  Raffle ID: ${widget.raffleId}");
    print("  Expiry Date: ${widget.expiryDate}");
    print("  Title: ${widget.title}");
    print("  Guesses: ${widget.guesses}");
    print("  Total Price: ${widget.totalPrice}");
  }

  Future<void> _fetchUserTypeAndTickets() async {
    try {
      // Fetch the current user's userType from Firestore
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists) {
        String userType = userDoc['userType'];
        setState(() {
          isCreator = userType == 'creator';
        });
        print("User type fetched: ${isCreator ? 'Creator' : 'Regular User'}");
      }

      // Fetch the total tickets bought for this raffle from raffle_tickets collection
      QuerySnapshot ticketsSnapshot = await FirebaseFirestore.instance
          .collection('raffle_tickets')
          .where('raffleId', isEqualTo: widget.raffleId)
          .get();

      setState(() {
        totalTicketsBought = ticketsSnapshot.size; // Total tickets bought for this raffle
      });
      print("Total tickets bought for raffle ${widget.raffleId}: $totalTicketsBought");
    } catch (e) {
      print("Error fetching user type or tickets: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double ticketWidth = screenWidth * 0.92;
    double indentWidth = ticketWidth * 0.07;
    double indentPosition = (140 - widget.indentHeight) / 2;
    double fontScale = screenWidth * 0.045;
    double buttonWidth = screenWidth * 0.22;
    double buttonHeight = screenWidth * 0.07;

    // Check if the raffle has expired
    bool isExpired = widget.expiryDate.isBefore(DateTime.now());
    print("Raffle ${widget.raffleId} expired status: $isExpired");

    return Stack(
      children: [
        // Main container with rounded corners and conditional color based on expiration
        Container(
          width: ticketWidth,
          height: 140,
          decoration: BoxDecoration(
            color: isExpired 
                ? const Color.fromARGB(255, 242, 242, 242) // Grey color for expired raffles
                : const Color.fromARGB(255, 200, 200, 200), // Default color for active raffles
            border: Border.all(color:  isExpired ? const Color.fromARGB(255, 200, 200, 200) : const Color(0xffff5f00), width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        // Left circular cutout for indent
        Positioned(
          left: -indentWidth / 2,
          top: indentPosition,
          child: Container(
            width: indentWidth,
            height: widget.indentHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              border: Border.all(color:  isExpired ? const Color.fromARGB(255, 200, 200, 200) : const Color(0xffff5f00), width: 2),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Right circular cutout for indent
        Positioned(
          right: -indentWidth / 2,
          top: indentPosition,
          child: Container(
            width: indentWidth,
            height: widget.indentHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              border: Border.all(color:  isExpired ? const Color.fromARGB(255, 200, 200, 200) : const Color(0xffff5f00), width: 2),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Title: Raffle + ID
        Positioned(
          top: 12, // Moved up slightly
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "#${widget.raffleId}",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontScale * 0.65,
                  fontWeight: FontWeight.bold,
                  color:  isExpired ? const Color.fromARGB(255, 200, 200, 200) : const Color(0xffff5f00)
                ),
              ),
            ],
          ),
        ),
        // Valid Until Date
        Positioned(
          top: 10,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 235, 235),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "Valid Until ${widget.expiryDate.toLocal().toString().split(' ')[0]}",
              style: TextStyle(
                fontSize: fontScale * 0.7,
                fontWeight: FontWeight.w400,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ),
        ),
        // Dotted Line
        Positioned(
          top: 45, // Moved up slightly
          left: 20,
          right: 20,
          child: Dash(
            length: ticketWidth - 44,
            dashLength: 6,
            dashColor:  isExpired ? const Color.fromARGB(255, 200, 200, 200) : const Color(0xffff5f00)
          ),
        ),
        // Title, Guesses/Tickets Bought, and Total Price
        Positioned(
          bottom: 10, // Adjusted down slightly
          left: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prize title
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: fontScale,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // Display based on user role
              Text(
                isCreator ? "$totalTicketsBought Tickets Bought" : "${widget.guesses} Guesses",
                style: TextStyle(
                  fontSize: fontScale * 0.7,
                  fontWeight: FontWeight.w400,
                ),
              ),
              // Total Price display
              Text(
                "Total: \$${widget.totalPrice.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: fontScale * 0.7,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF000000),
                ),
              ),
            ],
          ),
        ),
        // "View" Button
        Positioned(
          right: 20,
          bottom: 15,
          child: Container(
            width: buttonWidth,
            height: buttonHeight,
            decoration: BoxDecoration(
              color:  isExpired ? const Color.fromARGB(255, 200, 200, 200) : const Color(0xffff5f00),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              "View",
              style: TextStyle(
                fontSize: fontScale * 0.9,
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

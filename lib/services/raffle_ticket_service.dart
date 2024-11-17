import 'package:cloud_firestore/cloud_firestore.dart';

class RaffleTicketService {
 final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to create a new raffle ticket
  // Function to create a new raffle ticket
  Future<void> createRaffleTicket({
    required String raffleId,
    required String userId,
    required String raffleTitle,
    required DateTime expiryDate,
    required double xCoord,
    required double yCoord,
    required double price, // New price parameter
  }) async {
    try {
      // Generate a unique ticket ID
      String ticketId = _firestore.collection('raffle_tickets').doc().id;

      // Add the raffle ticket data
      await _firestore.collection('raffle_tickets').doc(ticketId).set({
        'ticketId': ticketId, 
        'raffleId': raffleId,
        'userId': userId,
        'raffleTitle': raffleTitle,
        'raffleExpiryDate': Timestamp.fromDate(expiryDate),
        'xCoord': xCoord,
        'yCoord': yCoord,
        'price': price, // Save price to Firestore
        'createdAt': FieldValue.serverTimestamp(),
      });
      print("Raffle ticket saved successfully!");
    } catch (e) {
      print("Error saving raffle ticket: $e");
      rethrow;
    }
  }

  // Function to get all raffle tickets for the user


  // Function to get all raffle tickets for the user
  Future<List<Map<String, dynamic>>> getRaffleTicketsForUser(String userId) async {
    try {
      // Query the `raffle_tickets` collection where `userId` matches the current user
      QuerySnapshot ticketSnapshot = await _firestore
          .collection('raffle_tickets')
          .where('userId', isEqualTo: userId)
          .get();

      List<Map<String, dynamic>> tickets = [];

      // Temporary map to hold guess counts by raffleId
      Map<String, Map<String, dynamic>> ticketMap = {};

      for (var doc in ticketSnapshot.docs) {
        var ticketData = doc.data() as Map<String, dynamic>;
        String raffleId = ticketData['raffleId'];

        // If the raffleId is already in the map, increment the guess count
        if (ticketMap.containsKey(raffleId)) {
          ticketMap[raffleId]!['guessCount'] += 1;
        } else {
          // Otherwise, add the raffle ticket to the map with guessCount initialized to 1
          ticketData['guessCount'] = 1;
          ticketMap[raffleId] = ticketData;
        }
      }

      // Convert the map values back to a list for easier usage
      tickets = ticketMap.values.toList();

      return tickets;
    } catch (e) {
      print("Error fetching raffle tickets: $e");
      return [];
    }
  }



  // Function to check if the user has enough credits
  Future<bool> hasEnoughCredits(int totalGuesses, int userCredits, double costPerGuess) async {
    return (userCredits >= totalGuesses * costPerGuess);
  }
}

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
    QuerySnapshot ticketSnapshot = await _firestore
        .collection('raffle_tickets')
        .where('userId', isEqualTo: userId)
        .get();

    print("Fetching raffle tickets for userId: $userId");

    return ticketSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Normalize field names
      return {
        'raffleId': data['raffleId'],
        'expiryDate': data['expiryDate'] ?? data['raffleExpiryDate'],
        'raffleTitle': data['raffleTitle'],
        'guessCount': data['guessCount'] ?? 0,
        'totalPrice': data['price'] ?? 0.0,
      };
    }).toList();
  } catch (e) {
    print("Error fetching raffle tickets: $e");
    return [];
  }
}

  // Function to check if the user has enough credits
 Future<bool> hasEnoughCredits(int totalGuesses, int userCredits, double costPerGuess) async {
  // Safely calculate
  return userCredits >= (totalGuesses * costPerGuess).ceil();
}


}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
Future<String?> getCurrentUserId() async {
    final user = _auth.currentUser;
    return user?.uid;
  }  Future<void> addGuessToCart({
    required String raffleId,
    required String userId,
    required String raffleTitle,
    required DateTime expiryDate,
    required double xCoord,
    required double yCoord,
    required double price,
  }) async {
    await _firestore.collection('cart').add({
      'raffleId': raffleId,
      'userId': userId,
      'raffleTitle': raffleTitle,
      'expiryDate': expiryDate,
      'xCoord': xCoord,
      'yCoord': yCoord,
      'price': price,
      'addedAt': Timestamp.now(),
    });
  }

  Future<List<Map<String, dynamic>>> getCartItemsForUser(String userId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('cart')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<double> calculateCartTotal(String userId) async {
    List<Map<String, dynamic>> cartItems = await getCartItemsForUser(userId);
    double total = 0.0;

    for (var item in cartItems) {
      total += item['price'] ?? 0.0;
    }

    return total;
  }

  Future<bool> deductCredits(String userId, double totalAmount) async {
  try {
    final userRef = _firestore.collection('users').doc(userId);

    return await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);

      if (!userSnapshot.exists) {
        throw Exception("User not found.");
      }

      double currentCredits = (userSnapshot['credits'] ?? 0).toDouble();

      if (currentCredits < totalAmount) {
        return false; // Insufficient credits
      }

      // Deduct credits
      transaction.update(userRef, {
        'credits': currentCredits - totalAmount,
      });

      return true; // Deduction successful
    });
  } catch (e) {
    print("Error deducting credits: $e");
    return false; // Transaction failed
  }
}


 // Function to transfer cart items to raffle_tickets and clear the cart upon checkout
Future<void> checkoutCart(String userId) async {
  WriteBatch batch = _firestore.batch();
  CollectionReference raffleTicketsRef = _firestore.collection('raffle_tickets');
  CollectionReference cartRef = _firestore.collection('cart');

  // Fetch all cart items for the user
  QuerySnapshot cartSnapshot = await cartRef.where('userId', isEqualTo: userId).get();

  for (var doc in cartSnapshot.docs) {
    Map<String, dynamic> cartItem = doc.data() as Map<String, dynamic>;

    // Prepare the raffle ticket data from the cart item, renaming `expiryDate` to `raffleExpiryDate`
    var ticketData = {
      'raffleId': cartItem['raffleId'],
      'userId': userId,
      'raffleTitle': cartItem['raffleTitle'],
      'raffleExpiryDate': cartItem['expiryDate'], // Use `raffleExpiryDate` instead of `expiryDate`
      'xCoord': cartItem['xCoord'],
      'yCoord': cartItem['yCoord'],
      'price': cartItem['price'],
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Add to raffle_tickets collection and remove from cart in a single batch
    batch.set(raffleTicketsRef.doc(), ticketData);
    batch.delete(cartRef.doc(doc.id));
  }

  // Commit the batch to complete the checkout
  await batch.commit();
}

}

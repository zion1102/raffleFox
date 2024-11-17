import 'package:cloud_firestore/cloud_firestore.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addGuessToCart({
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

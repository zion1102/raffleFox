import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RaffleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Function to upload images to Firebase Storage
  Future<String> _uploadImage(File imageFile, String folderPath, String fileName) async {
    try {
      String uniqueFileName = '$fileName${DateTime.now().millisecondsSinceEpoch}';
      Reference ref = _storage.ref().child('$folderPath/$uniqueFileName');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRafflesByCreator(String creatorId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('raffles')
          .where('creatorId', isEqualTo: creatorId)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching raffles by creator: $e");
      return [];
    }
  }

  // Function to add raffle to Firestore
  Future<void> addRaffle({
    required String title,
    required String description,
    required DateTime expiryDate,
    required String category,
    required double costPer,
    required File pictureFile,
    required File editedGamePictureFile,
    required File uneditedGamePictureFile,
    required String creatorId,
    String? detailOne,
    String? detailTwo,
    String? detailThree,
    required String raffleId,
    required int ticketsSold,
  }) async {
    try {
      String pictureUrl = await _uploadImage(pictureFile, 'raffles', 'raffle_picture');
      String editedGamePictureUrl = await _uploadImage(editedGamePictureFile, 'raffles', 'edited_game_picture');
      String uneditedGamePictureUrl = await _uploadImage(uneditedGamePictureFile, 'raffles', 'unedited_game_picture');

      await _firestore.collection('raffles').doc(raffleId).set({
        'title': title,
        'description': description,
        'expiryDate': Timestamp.fromDate(expiryDate),
        'category': category,
        'costPer': costPer,
        'ticketsSold': ticketsSold,
        'likes': 0,
        'detailOne': detailOne ?? '',
        'detailTwo': detailTwo ?? '',
        'detailThree': detailThree ?? '',
        'picture': pictureUrl,
        'editedGamePicture': editedGamePictureUrl,
        'uneditedGamePicture': uneditedGamePictureUrl,
        'raffleId': raffleId,
        'creatorId': creatorId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("Raffle added successfully with creatorId: $creatorId");
    } catch (e) {
      print("Error adding raffle: $e");
      rethrow;
    }
  }

  // Function to fetch the most recent raffle from Firestore
  Future<Map<String, dynamic>?> fetchMostRecentRaffle() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('raffles')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot doc = querySnapshot.docs.first;
        return doc.data() as Map<String, dynamic>;
      } else {
        print("No raffles found.");
      }
    } catch (e) {
      print("Error fetching most recent raffle: $e");
    }
    return null;
  }

  // Fetch the most popular raffles based on likes
  Future<List<Map<String, dynamic>>> getMostPopularRaffles() async {
    try {
      QuerySnapshot userLikesSnapshot = await _firestore.collection('userLikes').get();
      Map<String, int> likesCount = {};

      for (var doc in userLikesSnapshot.docs) {
        String raffleId = doc['raffleId'];
        likesCount[raffleId] = (likesCount[raffleId] ?? 0) + 1;
      }

      List<MapEntry<String, int>> sortedLikes = likesCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      List<String> topRaffleIds = sortedLikes.take(6).map((entry) => entry.key).toList();

      DateTime now = DateTime.now();
      List<Map<String, dynamic>> topRaffles = [];
      for (String raffleId in topRaffleIds) {
        DocumentSnapshot raffleDoc = await _firestore.collection('raffles').doc(raffleId).get();
        if (raffleDoc.exists) {
          Map<String, dynamic> raffleData = raffleDoc.data() as Map<String, dynamic>;
          if ((raffleData['expiryDate'] as Timestamp).toDate().isAfter(now)) {
            raffleData['likes'] = likesCount[raffleId];
            topRaffles.add(raffleData);
          }
        }
      }

      return topRaffles;
    } catch (e) {
      print("Error fetching most popular raffles: $e");
      return [];
    }
  }

  // Fetch raffles that are ending soon (within the next week)
  Future<List<Map<String, dynamic>>> getEndingSoonRaffles() async {
    try {
      DateTime now = DateTime.now();
      DateTime endOfWeek = now.add(const Duration(days: 8));

      QuerySnapshot querySnapshot = await _firestore
          .collection('raffles')
          .where('expiryDate', isGreaterThan: Timestamp.fromDate(now))
          .where('expiryDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
          .orderBy('expiryDate')
          .limit(6)
          .get();
   
      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching raffles ending soon: $e");
      return [];
    }
  }



  // Fetch raffles by categories
Future<List<Map<String, dynamic>>> getTopRaffles() async {
  try {
    print("Fetching top raffles from Firestore...");

    // Define the current date as a Firestore-compatible timestamp
    Timestamp currentDate = Timestamp.fromDate(DateTime.now());

    // Query Firestore
    QuerySnapshot querySnapshot = await _firestore
        .collection('raffles')
        .where('expiryDate', isGreaterThan: currentDate) // Only fetch non-expired raffles
        .orderBy('ticketsSold', descending: true)       // Order by most tickets sold
        .orderBy('title')                               // Secondary order by title alphabetically
        .limit(5)                                       // Limit to 5 results
        .get();

    print("Query result: ${querySnapshot.docs.length} documents fetched.");

    // Transform and return the data
    return querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['raffleId'] = doc.id; // Add the document ID to the data
      print("Fetched Raffle: ${data['title']}, Tickets Sold: ${data['ticketsSold']}, Expiry Date: ${data['expiryDate']}");
      return data;
    }).toList();
  } catch (e) {
    print("Error fetching top raffles: $e");
    return [];
  }
}


Future<Map<String, List<Map<String, dynamic>>>> getRafflesByCategories(List<String> categories) async {
  Map<String, List<Map<String, dynamic>>> rafflesByCategory = {};

  try {
    Timestamp currentDate = Timestamp.fromDate(DateTime.now());

    for (String category in categories) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('raffles')
          .where('category', isEqualTo: category)
          .where('expiryDate', isGreaterThan: currentDate)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        rafflesByCategory[category] = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['raffleId'] = doc.id;
          return data;
        }).toList();
      }
    }

    return rafflesByCategory;
  } catch (e) {
    print("Error fetching raffles by categories: $e");
    return {};
  }
}

  // Fetch raffles liked by the user
  // Fetch raffles liked by the user
  Future<List<Map<String, dynamic>>> getLikedRaffles(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('userLikes')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> likedRaffles = [];

      for (var doc in querySnapshot.docs) {
        var likeData = doc.data() as Map<String, dynamic>;
        if (likeData['raffleId'] != null) {
          DocumentSnapshot raffleDoc = await _firestore.collection('raffles').doc(likeData['raffleId']).get();
          if (raffleDoc.exists) {
            var raffleData = raffleDoc.data() as Map<String, dynamic>;
            raffleData['raffleId'] = likeData['raffleId'];
            // Ensure expiryDate is converted to DateTime
            if (raffleData['expiryDate'] is Timestamp) {
              raffleData['expiryDate'] = (raffleData['expiryDate'] as Timestamp).toDate();
            }
            likedRaffles.add(raffleData);
          }
        }
      }
      return likedRaffles;
    } catch (e) {
      print("Error fetching liked raffles: $e");
      return [];
    }
  }

Future<List<Map<String, dynamic>>> getRaffleTicketsForUser(String userId) async {
  try {
    print("Fetching raffle tickets for userId: $userId");

    QuerySnapshot ticketSnapshot = await _firestore
        .collection('raffle_tickets')
        .where('userId', isEqualTo: userId)
        .get();

    print("Raffle tickets fetched: ${ticketSnapshot.docs.length}");

    List<Map<String, dynamic>> tickets = [];

    for (var doc in ticketSnapshot.docs) {
      Map<String, dynamic> ticketData = doc.data() as Map<String, dynamic>;
      print("Fetched ticket: ${ticketData['raffleId']} - ${ticketData['raffleTitle']}");

      // Additional checks for missing or null data
      if (ticketData['raffleId'] == null || ticketData['expiryDate'] == null) {
        print("Skipping ticket due to missing raffleId or expiryDate.");
        continue;
      }

      // Convert expiryDate if necessary
      if (ticketData['expiryDate'] is Timestamp) {
        ticketData['expiryDate'] = (ticketData['expiryDate'] as Timestamp).toDate();
      }

      tickets.add(ticketData);
    }

    print("Processed raffle tickets: ${tickets.length}");
    return tickets;
  } catch (e) {
    print("Error fetching raffle tickets: $e");
    return [];
  }
}


Future<List<Map<String, dynamic>>> getCartTickets(String userId) async {
  try {
    print("Fetching cart tickets for userId: $userId");

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('cart')
        .where('userId', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> cartTickets = [];

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Fetch title from raffles if missing
      if (data['title'] == null && data['raffleId'] != null) {
        DocumentSnapshot raffleDoc = await _firestore.collection('raffles').doc(data['raffleId']).get();
        if (raffleDoc.exists) {
          data['title'] = raffleDoc.get('title');
        }
      }

      // Ensure expiryDate is converted if necessary
      if (data['expiryDate'] is Timestamp) {
        data['expiryDate'] = (data['expiryDate'] as Timestamp).toDate();
      }

      // Calculate totalPrice if necessary
      data['totalPrice'] = data['price'] ?? 0.0;

      cartTickets.add(data);
    }

    return cartTickets;
  } catch (e) {
    print("Error fetching cart tickets: $e");
    return [];
  }
}


  // Fetch ending soon raffles relevant to user
Future<List<Map<String, dynamic>>> getUserRelevantEndingSoonRaffles(String userId) async {
  try {
    DateTime now = DateTime.now();
    DateTime endOfWeek = now.add(const Duration(days: 8));

    // Step 1: Fetch liked raffles for the user
    print("Fetching liked raffles for userId: $userId");
    QuerySnapshot likedRafflesSnapshot = await _firestore
        .collection('userLikes')
        .where('userId', isEqualTo: userId)
        .get();

    // Step 2: Fetch bought tickets for the user
    print("Fetching bought tickets for userId: $userId");
    QuerySnapshot boughtTicketsSnapshot = await _firestore
        .collection('raffle_tickets')
        .where('userId', isEqualTo: userId)
        .get();

    // Step 3: Fetch raffles in user's cart
    print("Fetching cart tickets for userId: $userId");
    QuerySnapshot cartTicketsSnapshot = await _firestore
        .collection('cart')
        .where('userId', isEqualTo: userId)
        .get();

    // Collect raffle IDs from all the snapshots
    Set<String> relevantRaffleIds = {};
    print("Processing liked raffles...");
    for (var doc in likedRafflesSnapshot.docs) {
      if (doc['raffleId'] != null) {
        relevantRaffleIds.add(doc['raffleId']);
      } else {
        print("Warning: Null raffleId in liked raffles for docId: ${doc.id}");
      }
    }

    print("Processing bought tickets...");
    for (var doc in boughtTicketsSnapshot.docs) {
      if (doc['raffleId'] != null) {
        relevantRaffleIds.add(doc['raffleId']);
      } else {
        print("Warning: Null raffleId in bought tickets for docId: ${doc.id}");
      }
    }

    print("Processing cart tickets...");
    for (var doc in cartTicketsSnapshot.docs) {
      if (doc['raffleId'] != null) {
        relevantRaffleIds.add(doc['raffleId']);
      } else {
        print("Warning: Null raffleId in cart for docId: ${doc.id}");
      }
    }

    print("Total relevant raffle IDs found: ${relevantRaffleIds.length}");

    // Fetch raffle details for relevant raffle IDs that are ending soon
    List<Map<String, dynamic>> endingSoonRaffles = [];

   for (String raffleId in relevantRaffleIds) {
  print("Fetching raffle data for raffleId: $raffleId");
  DocumentSnapshot raffleDoc = await _firestore.collection('raffles').doc(raffleId).get();

  if (raffleDoc.exists) {
    Map<String, dynamic>? raffleData = raffleDoc.data() as Map<String, dynamic>?;

    if (raffleData != null && raffleData['expiryDate'] != null && raffleData['title'] != null) {
      DateTime expiryDate = (raffleData['expiryDate'] as Timestamp).toDate();


      // Only include raffles that are ending soon
      if (expiryDate.isAfter(now) && expiryDate.isBefore(endOfWeek)) {
        raffleData['raffleId'] = raffleId; // Assign raffleId to data map
        raffleData['expiryDate'] = expiryDate; // Convert Timestamp to DateTime
        endingSoonRaffles.add(raffleData);
      } else {
        print("Raffle $raffleId expiryDate $expiryDate is not within the ending soon range.");
      }
    } else {
      print("Warning: Raffle data for $raffleId is incomplete or missing required fields.");
    }
  } else {
    print("Warning: Raffle document does not exist for raffleId: $raffleId");
  }
}


    print("Total ending soon raffles found: ${endingSoonRaffles.length}");
    return endingSoonRaffles;
  } catch (e) {
    print("Error fetching user-relevant ending soon raffles: $e");
    return [];
  }
}



}

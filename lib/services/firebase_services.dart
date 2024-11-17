import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:raffle_fox/config/firebase.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;


class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
   final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
 // Method to get the current user's UID
  Future<String?> getCurrentUserId() async {
    try {
      User? currentUser = FirebaseConfig.authInstance!.currentUser;
      return currentUser?.uid;
    } catch (e) {
      print("Error fetching current user ID: $e");
      return null;
    }
  }
  // Function to create a new user with debugging
Future<File?> compressImage(File file) async {
    final image = img.decodeImage(file.readAsBytesSync());
    final resizedImage = img.copyResize(image!, width: 800);
    final compressedBytes = img.encodeJpg(resizedImage, quality: 80);
    final tempDir = await getTemporaryDirectory();
    final compressedFile = File('${tempDir.path}/compressed_image.jpg')..writeAsBytesSync(compressedBytes);
    return compressedFile;
  }

  // Function to upload image and get URL
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      File? compressedImage = await compressImage(imageFile); // Compress image
      if (compressedImage == null) return null;

      final ref = _storage.ref().child('profile_pictures/$userId.jpg');
      await ref.putFile(compressedImage);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // Function to create user with profile image
 Future<User?> createUser({
  required String email,
  required String password,
  required String name,
  required String phone,
  required int age,
  required String userType,
  File? profilePicture,
}) async {
  try {
    // Attempt to create the user with Firebase Authentication
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Add additional user info to Firestore or handle profilePicture upload if needed

    return userCredential.user;
  } on FirebaseAuthException catch (e) {
    // Forward the Firebase-specific error to be displayed in the UI
    throw Exception(_getFirebaseErrorMessage(e));
  } catch (e) {
    // Catch any other errors
    throw Exception("An unexpected error occurred. Please try again later.");
  }
}

String _getFirebaseErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return 'This email is already in use. Please use a different email.';
    case 'invalid-email':
      return 'The email address is not valid. Please enter a valid email.';
    case 'weak-password':
      return 'The password is too weak. Please use a stronger password.';
    case 'operation-not-allowed':
      return 'Account creation is not enabled. Please contact support.';
    default:
      return 'An error occurred. Please try again.';
  }
}



  // Function to send email verification with debugging
  Future<void> sendEmailConfirmation(UserCredential userCredential) async {
    try {
      print("Checking if email is verified");
      if (!userCredential.user!.emailVerified) {
        print("Email not verified. Sending email verification...");
        await userCredential.user!.sendEmailVerification();
        print("Verification email sent to ${userCredential.user!.email}");
      } else {
        print("Email is already verified.");
      }
    } catch (e) {
      print("Error sending verification email: $e");
    }
  }

  // Function to log in the user
Future<UserCredential?> loginUser({
  required String email,
  required String password,
}) async {
  try {
    print("Attempting to log in user with email: $email");

    if (FirebaseConfig.authInstance == null) {
      throw Exception("FirebaseAuth instance is not initialized.");
    }

    UserCredential userCredential = await FirebaseConfig.authInstance!.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    print("User logged in successfully: ${userCredential.user!.uid}");
    return userCredential;
  } catch (e) {
    print("Error logging in: $e");
    return null;
  }
}


  // Function to delete the user's account
Future<void> deleteUserAccount() async {
    try {
      User? user = FirebaseConfig.authInstance!.currentUser;
      if (user != null) {
        // Remove user's data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete user's account from Firebase Authentication
        await user.delete();

        print("User account deleted successfully.");
      }
    } catch (e) {
      print("Error deleting user account: $e");
    }
  }
 Future<String?> getUserType(String uid) async {
  try {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();

    if (userDoc.exists && userDoc.data() != null) {
      final data = userDoc.data() as Map<String, dynamic>;
      return data['userType'] as String?; // Fetch the userType
    } else {
      print("User document does not exist for UID: $uid");
      return null;
    }
  } catch (e) {
    print("Error fetching userType for UID $uid: $e");
    return null;
  }
}


  // Function to fetch the current user's details from Firestore
Future<Map<String, dynamic>?> getUserDetails() async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (docSnapshot.exists) {
        print("User details fetched: ${docSnapshot.data()}");
        return docSnapshot.data() as Map<String, dynamic>;
      } else {
        print("User document does not exist.");
        return null;
      }
    } else {
      print("No authenticated user.");
      return null;
    }
  } catch (e) {
    print("Error fetching user details: $e");
    return null;
  }
}


  // Fetch the profile picture URL of the current user or a default one
  Future<String> getProfilePicture() async {
    Map<String, dynamic>? userDetails = await getUserDetails();
    if (userDetails != null && userDetails['profilePicture'] != '') {
      return userDetails['profilePicture'];
    } else {
      // Default profile picture
      return 'https://via.placeholder.com/150';
    }
  }

  // Function to update the user's credits (example of updating a field)
  Future<void> updateUserCredits(String uid, int newCredits) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'credits': newCredits,
      });
      print("User credits updated successfully.");
    } catch (e) {
      print("Error updating user credits: $e");
    }
  }


  Future<void> logoutUser() async {
  try {
    await FirebaseConfig.authInstance!.signOut();
    print("User logged out successfully.");
  } catch (e) {
    print("Error logging out: $e");
  }
}


Future<List<Map<String, dynamic>>> getRecentLikedRaffles() async {
  try {
    String? userId = await getCurrentUserId();
    if (userId == null) return [];

    // Fetch liked raffles for the user from the `userLikes` table
    QuerySnapshot likedRafflesSnapshot = await _firestore
        .collection('userLikes')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true) // Order by liked date to get recent likes
        .limit(4)
        .get();

    List<Map<String, dynamic>> likedRaffles = [];

    for (var doc in likedRafflesSnapshot.docs) {
      var likeData = doc.data() as Map<String, dynamic>;

      if (likeData['raffleId'] != null) {
        // Fetch raffle details using raffleId
        DocumentSnapshot raffleDoc = await _firestore.collection('raffles').doc(likeData['raffleId']).get();
        if (raffleDoc.exists) {
          var raffleData = raffleDoc.data() as Map<String, dynamic>;
          DateTime expiryDate = (raffleData['expiryDate'] as Timestamp).toDate();

          // Only add if not expired
          if (expiryDate.isAfter(DateTime.now())) {
            raffleData['raffleId'] = likeData['raffleId']; // Ensure raffleId is included
            likedRaffles.add(raffleData);
          }
        }
      }
    }

    return likedRaffles;
  } catch (e) {
    print("Error fetching liked raffles: $e");
    return [];
  }
}

  Future<void> addRaffleTicket({
    required String userId,
    required String raffleId,
    required String raffleTitle,
    required DateTime expiryDate,
    required DateTime purchasedAt,
  }) async {
    try {
      final raffleTicketsRef = _firestore.collection('raffle_tickets');
      await raffleTicketsRef.add({
        'userId': userId,
        'raffleId': raffleId,
        'raffleTitle': raffleTitle,
        'expiryDate': Timestamp.fromDate(expiryDate),
        'purchasedAt': Timestamp.fromDate(purchasedAt),
      });
    } catch (e) {
      print('Error adding raffle ticket: $e');
    }
  }


     Future<List<Map<String, dynamic>>> getUserTopUps(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('topUps')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching top-ups: $e");
      return [];
    }
  }

  // Fetch liked raffles by user ID
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

  // Fetch tickets added to cart by user ID
  Future<List<Map<String, dynamic>>> getCartTickets(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('cart')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching cart tickets: $e");
      return [];
    }
  }

  // Fetch tickets bought by user ID
  Future<List<Map<String, dynamic>>> getBoughtTickets(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('raffle_tickets')
          .where('userId', isEqualTo: userId)
          .orderBy('purchasedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching bought tickets: $e");
      return [];
    }
  }
}

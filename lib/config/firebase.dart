import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static FirebaseAuth? authInstance;
  static FirebaseFirestore? firestoreInstance;

  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully');

      // Set the instances after initialization
      authInstance = FirebaseAuth.instance;
      firestoreInstance = FirebaseFirestore.instance;

      print('Firestore and Auth instances initialized');
    } catch (e) {
      print('Error initializing Firebase: $e');
    }
  }
}

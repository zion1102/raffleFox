import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request notification permissions
    await _firebaseMessaging.requestPermission();

    // Initialize Flutter Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    await _flutterLocalNotificationsPlugin.initialize(settings);

    // Listen for background messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(
          message.notification!.title,
          message.notification!.body,
        );
      }
    });
  }
 

  Future<void> _showNotification(String? title, String? body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'raffle_notifications',
      'Raffle Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformDetails,
    );
  }

  Future<String?> getDeviceToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print('Device Token: $fcmToken');
    return await _firebaseMessaging.getToken();
    
  }
}

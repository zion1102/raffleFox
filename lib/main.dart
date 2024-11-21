import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:raffle_fox/config/firebase.dart';
import 'package:raffle_fox/providers/nav_bar_provider.dart';
import 'package:raffle_fox/services/notification_service.dart';
import 'routes/app_routes.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


Future<void> getDeviceToken() async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('Device Token: $fcmToken');
}
Future<void> initializeNotifications() async {
  // Define Android-specific initialization settings
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('mipmap/ic_launcher');

  // Define iOS-specific initialization settings
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  // Cross-platform initialization settings
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid, // Added Android settings
    iOS: initializationSettingsDarwin, // Ensure this is set
  );

  // Initialize the plugin
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );
}


void onDidReceiveNotificationResponse(NotificationResponse response) {
  // Handle notification interactions
  print('Notification tapped with payload: ${response.payload}');
}

Future<void> requestPermissions() async {
  final bool? result = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

  if (result == null || !result) {
    print('Permissions not granted!');
  } else {
    print('Permissions granted!');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization
  await FirebaseConfig.initializeFirebase();

  // Set preferred orientation
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await Hive.openBox('searchHistory');

  // Request notification permissions and initialize notifications
  await requestPermissions(); // Request permissions first
  await initializeNotifications(); // Initialize after permissions
  
await getDeviceToken();
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NavBarProvider()), 
        ],
        child: MaterialApp(
          title: 'Raffle App',
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.initialRoute,
          routes: AppRoutes.routes,
          scaffoldMessengerKey: globalMessengerKey,
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0XFFFFFFFF),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
  }
}
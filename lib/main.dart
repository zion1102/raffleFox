import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:raffle_fox/blocs/guess/guess_bloc.dart';
import 'package:raffle_fox/config/firebase.dart';
import 'package:raffle_fox/providers/nav_bar_provider.dart';
import 'routes/app_routes.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> getDeviceToken() async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('Device Token: $fcmToken');
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  );
}

void onDidReceiveNotificationResponse(NotificationResponse response) {
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

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    print("Background task executed: $task");
    return Future.value(true);
  });
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
  await requestPermissions();
  await initializeNotifications();
  await getDeviceToken();

  // Initialize background task handling
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

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
        child: MultiBlocProvider(
          providers: [
            BlocProvider<GuessBloc>(create: (_) => GuessBloc()),
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
      ),
    );
  }
}

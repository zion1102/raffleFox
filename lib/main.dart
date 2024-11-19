import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:raffle_fox/config/firebase.dart';
import 'package:raffle_fox/providers/nav_bar_provider.dart';
import 'routes/app_routes.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.delayed(const Duration(seconds: 1)); // Simulate splash or delay for app readiness

  // Initialize Firebase via FirebaseConfig
  await FirebaseConfig.initializeFirebase();

  // Set preferred orientation to portrait mode
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await Hive.openBox('searchHistory');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss the keyboard when the user taps anywhere outside a text field
        FocusScope.of(context).unfocus();
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NavBarProvider()), // Provide NavBarProvider
        ],
        child: MaterialApp(
          title: 'Raffle App',
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.initialRoute,
          routes: AppRoutes.routes,
          scaffoldMessengerKey: globalMessengerKey, // Add global messenger key
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0XFFFFFFFF), // Global background color
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
  }
}

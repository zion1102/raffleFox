import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate to the home screen after a delay
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/home'); // Update with your actual home route
    });

    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/splash.jpeg', // Path to the splash image
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

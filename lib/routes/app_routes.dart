import 'package:flutter/material.dart';
import 'package:raffle_fox/pages/create_account_screen.dart';
import 'package:raffle_fox/pages/create_raffle.dart';
import 'package:raffle_fox/pages/game_screen.dart';
import 'package:raffle_fox/pages/login_screen.dart';
import 'package:raffle_fox/pages/onboard.dart';
import 'package:raffle_fox/pages/raffle_detail.dart';
import 'package:raffle_fox/pages/search_screen.dart';
import 'package:raffle_fox/pages/userProfile_screen.dart';
import 'package:raffle_fox/pages/landingPage.dart';
import 'package:raffle_fox/pages/shop_screen.dart';

class AppRoutes {
  static const String landingPage = '/landingPage';
  static const String shopScreen = '/shopScreen';
  static const String initialRoute = '/initialRoute';
  static const String createAccountScreen = '/create_account_screen';
  static const String onboardScreen = '/onboard';
  static const String raffleDetail = '/raffleDetail';
  static const String gameScreen = '/gameScreen';
  static const String profileScreen = '/profile';
  static const String loginScreen = '/login';
  static const String createRaffle = '/createRaffle';
  static const String searchScreen = '/search';

  static Map<String, WidgetBuilder> routes = {
    landingPage: (context) => const LandingPage(),
    createAccountScreen: (context) => const CreateAccountScreen(),
    initialRoute: (context) => const LandingPage(),
    onboardScreen: (context) => const OnboardingScreen(),
    shopScreen: (context) => const ShopScreen(),
    profileScreen: (context) => const UserProfileScreen(),
    loginScreen: (context) => const LoginScreen(),
    createRaffle: (context) => const CreateRaffleScreen(),
    searchScreen:(context) => const SearchScreen()
  };

  // Use onGenerateRoute for passing arguments dynamically
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case raffleDetail:
        if (settings.arguments is Map<String, dynamic>) {
          final raffleData = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => RaffleDetailScreen(raffleData: raffleData),
          );
        }
        return _errorRoute();  // Handle error if arguments aren't passed correctly

      case gameScreen:
        if (settings.arguments is Map<String, dynamic>) {
          final raffleData = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PickSpotScreen(raffleData: raffleData),  // Pass raffle data
          );
        }
        return _errorRoute();  // Handle error if arguments aren't passed correctly

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: const Center(child: Text('Something went wrong!')),
        );
      },
    );
  }
}

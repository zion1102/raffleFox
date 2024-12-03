import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:raffle_fox/pages/login_screen.dart';
import 'package:raffle_fox/blocs/auth/auth_bloc.dart';
import 'package:raffle_fox/services/firebase_services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFFFFFFF),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (int index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildOnboardScreen(
                  "Winning! 🙌🙌 ",
                  "On Raffle Fox, you win trips, prizes, events, devices - all the things that make life better, easier and fun! Always at a bargain!",
                  "assets/images/onboard_image_1.png",
                ),
                _buildOnboardScreen(
                  "Are you a winner? 🏆",
                  "Test your skill and give yourself the chance to win for a fraction of the cost.",
                  "assets/images/onboard_image_2.png",
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildIndicator(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildOnboardScreen(String title, String description, String imagePath) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(imagePath, height: 300),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        if (_currentPage == 1)
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (_) => AuthBloc(FirebaseService()),
                    child:  LoginScreen(),
                  ),
                ),
              );
            },
            child: const Text("Get Started"),
          ),
      ],
    );
  }

  Widget _buildIndicator() {
    return AnimatedSmoothIndicator(
      activeIndex: _currentPage,
      count: 2,
      effect: const WormEffect(),
    );
  }
}

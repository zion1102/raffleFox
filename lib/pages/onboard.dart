import 'package:flutter/material.dart';
import 'package:raffle_fox/pages/login_screen.dart';
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
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

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
                  screenHeight,
                  screenWidth,
                  "Winning! 🙌🙌 ",
                  "On Raffle Fox, you win trips, prizes, events, devices -  all the things that make life better, easier and fun! Always at a bargain!",
                  "assets/images/onboard_image_1.png",
                  "assets/images/decorative_background_1.png",
                ),
                _buildOnboardScreen(
                  screenHeight,
                  screenWidth,
                  "Are you a winner? 🏆",
                  "Test your skill and give yourself the chance to win for a fraction of the cost.",
                  "assets/images/onboard_image_2.png",
                  "assets/images/decorative_background_2.png",
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

  Widget _buildOnboardScreen(double screenHeight, double screenWidth,
      String title, String description, String imagePath, String backgroundPath) {
    return Stack(
      children: [
        // Background as a Container with decoration to ensure it fills the screen
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundPath),
                fit: BoxFit.cover, // Ensures full coverage of the screen
              ),
            ),
          ),
        ),
        // Content card
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(left: 24, right: 24, bottom: 60),
            padding: const EdgeInsets.all(16),
            width: screenWidth * 0.85, // Ensures both cards are the same width
            height: screenHeight * 0.6, // Ensures both cards are the same height
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    imagePath, // Your image here
                    width: screenWidth * 0.8,
                    height: screenHeight * 0.3,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0XFF202020),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0XFF000000),
                  ),
                ),
                if (_currentPage == 1)
                  const SizedBox(height: 20),
                if (_currentPage == 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0XFFF15B29), // orange button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 50),
                    ),
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Get Started",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator() {
    return AnimatedSmoothIndicator(
      activeIndex: _currentPage,
      count: 2,
      effect: const ScrollingDotsEffect(
        spacing: 20,
        activeDotColor: Color(0XFFFBBC04),
        dotColor: Color(0XFFF15B29),
        dotHeight: 20,
        dotWidth: 20,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'create_account_screen.dart'; // Import the CreateAccountScreen
import 'login_screen.dart'; // Import the LoginScreen

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: width,
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.05, // 5% padding for horizontal sides
              vertical: height * 0.02, // 2% padding for vertical space
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: height * 0.1), // 10% space at the top
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    94,
                  ),
                  child: Image.asset(
                    "assets/images/img_raffle_fox_logo.png",
                    height: height * 0.23, // Scales the logo based on screen height
                    width: width * 0.5, // Adjusts width dynamically
                  ),
                ),
                SizedBox(height: height * 0.03), // 3% spacing
                // "RaffleFox" Title
                Text(
                  "RaffleFox",
                  style: TextStyle(
                    color: const Color(0XFF202020),
                    fontSize: width * 0.13, // Scales font size based on width
                    fontFamily: 'Gibson',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: height * 0.01), // 1% spacing
                // "Are you clever like a fox?" text
                Text(
                  "Are you clever\nlike a fox?",
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0XFF222222),
                    fontSize: width * 0.06, // Scales font size
                    fontFamily: 'Gotham',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: height * 0.15), // 15% space before button
                // "Let's get started" button
                SizedBox(
                  width: width * 0.8, // 80% of screen width
                  height: height * 0.07, // 7% of screen height
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0XFFF15B29),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      // Navigate to Create Account screen when the button is clicked
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateAccountScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Let's get started",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.06, // Dynamic font size
                        fontFamily: 'Gibson',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.03), // 3% space
                // "I already have an account" + Icon
                GestureDetector(
                  onTap: () {
                    // Navigate to LoginScreen when this text is tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "I already have an account",
                        style: TextStyle(
                          color: const Color(0XE5202020),
                          fontSize: width * 0.04, // Scaled font size
                          fontFamily: 'Gotham',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(width: width * 0.02), // 2% space between text and icon
                      SvgPicture.asset(
                        "assets/images/Button.svg",
                        height: width * 0.07, // 7% of width
                        width: width * 0.07, // 7% of width
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

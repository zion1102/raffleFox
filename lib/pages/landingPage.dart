import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:raffle_fox/pages/create_account_screen.dart';
import 'package:raffle_fox/pages/login_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:raffle_fox/blocs/auth/auth_bloc.dart';
import 'package:raffle_fox/services/firebase_services.dart';

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
              horizontal: width * 0.05,
              vertical: height * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: height * 0.1),
                ClipRRect(
                  borderRadius: BorderRadius.circular(94),
                  child: Image.asset(
                    "assets/images/img_raffle_fox_logo.png",
                    height: height * 0.23,
                    width: width * 0.5,
                  ),
                ),
                SizedBox(height: height * 0.03),
                Text(
                  "RaffleFox",
                  style: TextStyle(
                    color: const Color(0XFF202020),
                    fontSize: width * 0.13,
                    fontFamily: 'Gibson',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: height * 0.01),
                Text(
                  "Are you clever\nlike a fox?",
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0XFF222222),
                    fontSize: width * 0.06,
                    fontFamily: 'Gotham',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: height * 0.15),
                SizedBox(
                  width: width * 0.8,
                  height: height * 0.07,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0XFFF15B29),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
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
                        fontSize: width * 0.06,
                        fontFamily: 'Gibson',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.03),
                GestureDetector(
                  onTap: () {
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "I already have an account",
                        style: TextStyle(
                          color: const Color(0XE5202020),
                          fontSize: width * 0.04,
                          fontFamily: 'Gotham',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      SvgPicture.asset(
                        "assets/images/Button.svg",
                        height: width * 0.07,
                        width: width * 0.07,
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

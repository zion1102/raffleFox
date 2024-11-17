import 'package:flutter/material.dart';
import 'package:raffle_fox/pages/create_raffle.dart';
import 'package:raffle_fox/pages/landingPage.dart';
import 'package:raffle_fox/pages/shop_screen.dart';
import 'package:raffle_fox/services/firebase_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailInputController = TextEditingController();
  final TextEditingController passwordInputController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  bool _obscurePassword = true; // Controls password visibility

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0XFFFFFFFF),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/img_image_15.png",
                fit: BoxFit.cover,
              ),
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.4),
                  const Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 50,
                      fontFamily: 'Gibson',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 50),
                  _buildFormSection(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailInput(BuildContext context) {
    return SizedBox(
      width: 334,
      child: TextFormField(
        controller: emailInputController,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "Email",
          hintStyle: const TextStyle(
            color: Color(0XFFD2D2D2),
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
          fillColor: const Color(0XFFF8F8F8),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
    );
  }

 Widget _buildPasswordInput(BuildContext context) {
  return SizedBox(
    width: 334,
    child: TextFormField(
      controller: passwordInputController,
      obscureText: _obscurePassword,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 14,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: "Password",
        hintStyle: const TextStyle(
          color: Color(0XFFD2D2D2),
          fontSize: 14,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        fillColor: const Color(0XFFF8F8F8),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword; // Toggle password visibility
            });
          },
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
  );
}


  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0XFFF15B29),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _loginUser,
        child: const Text(
          "Login",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontFamily: 'Gibson',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          _buildEmailInput(context),
          const SizedBox(height: 16),
          _buildPasswordInput(context),
          const SizedBox(height: 32),
          _buildSubmitButton(context),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const LandingPage(),
                ),
                (route) => false,
              );
            },
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'Gotham',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
void _loginUser() async {
  final email = emailInputController.text.trim();
  final password = passwordInputController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Failed"),
        content: const Text("Please enter both email and password."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
    return;
  }

  try {
    // Login the user using Firebase Authentication
    final userCredential = await _firebaseService.loginUser(
      email: email,
      password: password,
    );

    if (userCredential != null) {
      // Fetch `userType` from Firestore
      final uid = userCredential.user!.uid;
      final userType = await _firebaseService.getUserType(uid);

      if (userType == null) {
        throw Exception("Unable to determine user type.");
      }

      print("User logged in with userType: $userType");

      // Navigate to the appropriate screen based on userType
      if (userType == 'creator') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const CreateRaffleScreen(),
          ),
          (route) => false,
        );
      } else if (userType == 'user') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const ShopScreen(),
          ),
          (route) => false,
        );
      } else {
        throw Exception("Unknown user type: $userType");
      }
    } else {
      print("Failed to log in user.");
    }
  } catch (e) {
    print("Error logging in: $e");
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Login Failed"),
          content: Text(
            e.toString().contains('permission-denied')
                ? "You don't have permission to access this data. Please contact support."
                : "An error occurred. Please try again.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }
}

}

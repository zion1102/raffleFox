 import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:raffle_fox/services/firebase_services.dart';
import 'package:raffle_fox/pages/onboard.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedCirclePainter({required this.color, this.strokeWidth = 2.0, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    final double radius = (size.width / 2) - strokeWidth / 2;
    final double circumference = 2 * 3.141592653589793 * radius;
    final int dashCount = (circumference / (strokeWidth + gap)).floor();
    final double dashAngle = 2 * 3.141592653589793 / dashCount;

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = i * dashAngle;
      final double endAngle = startAngle + (dashAngle / 2);

      path.addArc(
        Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: radius),
        startAngle,
        endAngle - startAngle,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController emailInputController = TextEditingController();
  final TextEditingController passwordInputController = TextEditingController();
  final TextEditingController confirmPasswordInputController = TextEditingController();
  final TextEditingController phoneNumberInputController = TextEditingController();
  final TextEditingController nameInputController = TextEditingController();
  String selectedUserType = "regular";
  DateTime? selectedDateOfBirth;
  final FirebaseService _firebaseService = FirebaseService();
  File? _selectedImage;
  String countryCode = '+1';
  bool _obscurePassword = true;

  final ImagePicker _picker = ImagePicker();

  bool _isPasswordValid = true;
  final List<String> _passwordErrors = [];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  bool _validatePassword(String password) {
    _passwordErrors.clear();

    if (password.length < 8 || password.length > 16) {
      _passwordErrors.add('Password must be between 8 and 16 characters.');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      _passwordErrors.add('Password must contain an uppercase letter.');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      _passwordErrors.add('Password must contain a lowercase letter.');
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      _passwordErrors.add('Password must contain a number.');
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      _passwordErrors.add('Password must contain a special character.');
    }

    setState(() {
      _isPasswordValid = _passwordErrors.isEmpty;
    });

    return _isPasswordValid;
  }

Future<void> _createUser() async {
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
  );

  try {
    final user = await _firebaseService.createUser(
      email: emailInputController.text.trim(),
      password: passwordInputController.text.trim(),
      name: nameInputController.text,
      phone: countryCode + phoneNumberInputController.text.trim(),
      age: selectedDateOfBirth == null ? 0 : DateTime.now().year - selectedDateOfBirth!.year,
      userType: selectedUserType,
      profilePicture: _selectedImage,
    );

    Navigator.of(context).pop(); // Close the loading dialog

    if (user != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const OnboardingScreen()));
    } else {
      _showErrorDialog("Account creation failed. Please try again.");
    }
  } catch (e) {
    Navigator.of(context).pop(); // Close the loading dialog
    _showErrorDialog(e.toString());
  }
}

void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Account Creation Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}


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
                children: [
                  _buildProfileSection(context, size),
                  const SizedBox(height: 32),
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

  Widget _buildProfileSection(BuildContext context, Size size) {
    return SizedBox(
      height: size.height * 0.4,
      width: size.width,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Positioned(
            top: size.height * 0.08,
            left: 30,
            child: const Text(
              "Create\nAccount",
              style: TextStyle(
                color: Colors.black,
                fontSize: 50,
                fontFamily: 'Gibson',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.24,
            left: 30,
            child: GestureDetector(
              onTap: _pickImage,
              child: SizedBox(
                height: 90,
                width: 90,
                child: CustomPaint(
                  painter: DashedCirclePainter(color: Colors.black),
                  child: Center(
                    child: _selectedImage == null
                        ? SvgPicture.asset(
                            "assets/images/img_camera_icon.svg",
                            height: 30,
                            width: 30,
                          )
                        : ClipOval(
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              height: 80,
                              width: 80,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return _buildTextField(controller: nameInputController, hintText: "Name");
  }

  Widget _buildDateOfBirthPicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() {
            selectedDateOfBirth = pickedDate;
          });
        }
      },
      child: Container(
        width: 334,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0XFFF8F8F8),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          selectedDateOfBirth == null
              ? "Date of Birth"
              : DateFormat('yyyy-MM-dd').format(selectedDateOfBirth!),
          style: TextStyle(
            color: selectedDateOfBirth == null ? const Color(0XFFD2D2D2) : Colors.black,
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInput() {
    return _buildTextField(controller: emailInputController, hintText: "Email");
  }

  Widget _buildPasswordInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: passwordInputController,
          hintText: "Password",
          obscureText: _obscurePassword,
          suffixIcon: _obscurePassword ? Icons.visibility_off : Icons.visibility,
          onSuffixIconPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        if (!_isPasswordValid && _passwordErrors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _passwordErrors.map((error) => Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildConfirmPasswordInput() {
    return _buildTextField(
      controller: confirmPasswordInputController,
      hintText: "Confirm Password",
      obscureText: _obscurePassword,
      suffixIcon: _obscurePassword ? Icons.visibility_off : Icons.visibility,
      onSuffixIconPressed: () {
        setState(() {
          _obscurePassword = !_obscurePassword;
        });
      },
    );
  }

  Widget _buildPhoneNumberInput() {
    return Row(
      children: [
        CountryCodePicker(
          initialSelection: countryCode,
          onChanged: (country) {
            setState(() {
              countryCode = country.dialCode ?? '+1';
            });
          },
        ),
        Expanded(
          child: TextFormField(
            controller: phoneNumberInputController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: "Your number",
              filled: true,
              fillColor: const Color(0XFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
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
        onPressed: _createUser,
        child: const Text(
          "Done",
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

  Widget _buildUserTypeDropdown() {
    return SizedBox(
      width: 334,
      child: DropdownButtonFormField<String>(
        value: selectedUserType,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0XFFF8F8F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(26),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        onChanged: (String? newValue) {
          setState(() {
            selectedUserType = newValue!;
          });
        },
        items: <String>['regular', 'creator']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value[0].toUpperCase() + value.substring(1),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFormSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          _buildNameInput(),
          const SizedBox(height: 12),
          _buildDateOfBirthPicker(context),
          const SizedBox(height: 12),
          _buildEmailInput(),
          const SizedBox(height: 12),
          _buildPasswordInput(),
          const SizedBox(height: 12),
          _buildConfirmPasswordInput(),
          const SizedBox(height: 12),
          _buildPhoneNumberInput(),
          const SizedBox(height: 12),
          _buildUserTypeDropdown(),
          const SizedBox(height: 24),
          _buildSubmitButton(),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconPressed,
  }) {
    return SizedBox(
      width: 334,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
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
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(suffixIcon, color: Colors.grey),
                  onPressed: onSuffixIconPressed,
                )
              : null,
        ),
      ),
    );
  }
}


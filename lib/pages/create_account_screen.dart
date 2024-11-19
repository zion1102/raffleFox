import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:raffle_fox/services/firebase_services.dart';
import 'package:raffle_fox/pages/onboard.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';

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
  DateTime? selectedDateOfBirth;
  final FirebaseService _firebaseService = FirebaseService();
  File? _selectedImage;
  String countryCode = '+1'; // Default to US
  String countryIsoCode = 'TT'; // Default ISO code for the United States
  bool _obscurePassword = true;

  final ImagePicker _picker = ImagePicker();

  bool _isPasswordValid = true;
  final List<String> _passwordErrors = [];

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          countryCode = '+1';
          countryIsoCode = 'TT';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        setState(() {
          countryIsoCode = placemarks.first.isoCountryCode ?? 'TT';
          countryCode = CountryCode.fromCode(countryIsoCode).dialCode ?? '+1';
        });
      }
    } catch (e) {
      setState(() {
        countryCode = '+1';
        countryIsoCode = 'TT';
      });
    }
  }

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
        userType: "regular",
        profilePicture: _selectedImage,
      );

      Navigator.of(context).pop();

      if (user != null) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const OnboardingScreen()));
      } else {
        _showErrorDialog("Account creation failed. Please try again.");
      }
    } catch (e) {
      Navigator.of(context).pop();
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
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Column(
                  children: [
                    _buildProfileSection(context, size),
                    SizedBox(height: size.height * 0.04),
                    _buildFormSection(context, size),
                    SizedBox(height: size.height * 0.02),
                  ],
                ),
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
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Positioned(
            top: size.height * 0.1,
            left: size.width * 0.07,
            child: Text(
              "Create\nAccount",
              style: TextStyle(
                color: Colors.black,
                fontSize: size.width * 0.1,
                fontFamily: 'Gibson',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.25,
            left: size.width * 0.07,
            child: GestureDetector(
              onTap: _pickImage,
              child: SizedBox(
                height: size.width * 0.25,
                width: size.width * 0.25,
                child: CustomPaint(
                  painter: DashedCirclePainter(color: Colors.black),
                  child: Center(
                    child: _selectedImage == null
                        ? SvgPicture.asset(
                            "assets/images/img_camera_icon.svg",
                            height: size.width * 0.1,
                            width: size.width * 0.1,
                          )
                        : ClipOval(
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              height: size.width * 0.2,
                              width: size.width * 0.2,
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

 Widget _buildFormSection(BuildContext context, Size size) {
  return AutofillGroup(
    child: Column(
      children: [
        _buildNameInput(),
        SizedBox(height: size.height * 0.02),
        _buildDateOfBirthPicker(context), // Autofill not applicable for date picker
        SizedBox(height: size.height * 0.02),
        _buildEmailInput(),
        SizedBox(height: size.height * 0.02),
        _buildPasswordInput(),
        SizedBox(height: size.height * 0.02),
        _buildConfirmPasswordInput(),
        SizedBox(height: size.height * 0.02),
        _buildPhoneNumberInput(),
        SizedBox(height: size.height * 0.03),
        _buildSubmitButton(),
      ],
    ),
  );
}

 Widget _buildNameInput() {
  return _buildTextField(
    controller: nameInputController,
    hintText: "Name",
    autofillHints: [AutofillHints.name], // Autofill hint for name
  );
}

Widget _buildEmailInput() {
  return _buildTextField(
    controller: emailInputController,
    hintText: "Email",
    keyboardType: TextInputType.emailAddress,
    autofillHints: [AutofillHints.email], // Autofill hint for email
  );
}

Widget _buildDateOfBirthPicker(BuildContext context) {
  return SizedBox(
    width: double.infinity, // Match the width of other fields
    child: GestureDetector(
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
    ),
  );
}


 

 Widget _buildPasswordInput() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildTextField(
        controller: passwordInputController,
        hintText: "Password",
        obscureText: _obscurePassword,
        autofillHints: [AutofillHints.newPassword], // Autofill hint for new password
        suffixIcon: _obscurePassword ? Icons.visibility_off : Icons.visibility,
        onSuffixIconPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
        onChanged: (value) {
          _validatePassword(value);
        },
      ),
      const SizedBox(height: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPasswordHint(
            "Password must be between 8 and 16 characters",
            passwordInputController.text.length >= 8 &&
                passwordInputController.text.length <= 16,
          ),
          _buildPasswordHint(
            "Password must contain an uppercase letter",
            RegExp(r'[A-Z]').hasMatch(passwordInputController.text),
          ),
          _buildPasswordHint(
            "Password must contain a lowercase letter",
            RegExp(r'[a-z]').hasMatch(passwordInputController.text),
          ),
          _buildPasswordHint(
            "Password must contain a number",
            RegExp(r'\d').hasMatch(passwordInputController.text),
          ),
          _buildPasswordHint(
            "Password must contain a special character",
            RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(passwordInputController.text),
          ),
        ],
      ),
    ],
  );
}

  Widget _buildPasswordHint(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.red,
            fontSize: 12,
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
    autofillHints: [AutofillHints.newPassword],
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
        initialSelection: countryIsoCode,
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
          autofillHints: [AutofillHints.telephoneNumber],
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

  Widget _buildTextField({
  required TextEditingController controller,
  required String hintText,
  TextInputType keyboardType = TextInputType.text,
  bool obscureText = false,
  IconData? suffixIcon,
  VoidCallback? onSuffixIconPressed,
  ValueChanged<String>? onChanged,
  List<String>? autofillHints, // Add autofillHints parameter
}) {
  return SizedBox(
    width: double.infinity,
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      autofillHints: autofillHints, // Add autofill hints
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

import 'package:flutter/material.dart';
import 'package:raffle_fox/pages/userProfile_screen.dart';
import 'package:raffle_fox/pages/login_screen.dart';
import 'package:raffle_fox/services/firebase_services.dart'; // FirebaseService import

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 120,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        Positioned(
          left: 26,
          top: 60,
          right: 26,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Row containing profile picture and My Raffles button
              Row(
                children: [
                  FutureBuilder<String>(
                    future: FirebaseService().getProfilePicture(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey, // Loading state
                        );
                      } else if (snapshot.hasError) {
                        return const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.red, // Error state
                        );
                      } else {
                        return CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(snapshot.data!), // Use user's profile picture
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 10), // Small space between profile picture and button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 113,
                      height: 35,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF15B29),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'My Raffles',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'Gotham',
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 34,
                height: 35,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.settings, color: Colors.orange),
                  iconSize: 28,
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await FirebaseService().logoutUser();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>  LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Text('Log Out'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(110);
}

import 'package:flutter/material.dart';
import 'package:raffle_fox/pages/create_raffle.dart';
import 'package:raffle_fox/pages/userProfile_screen.dart';

class CreatorBottomNavBar extends StatefulWidget {
  final int selectedIndex; // To indicate the current selected index

  const CreatorBottomNavBar({super.key, this.selectedIndex = 0});

  @override
  _CreatorBottomNavBarState createState() => _CreatorBottomNavBarState();
}

class _CreatorBottomNavBarState extends State<CreatorBottomNavBar> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigate to the appropriate screen based on index
    switch (_currentIndex) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserProfileScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>  const CreateRaffleScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Create Raffle',
        ),
      ],
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
    );
  }
}

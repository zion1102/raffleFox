import 'package:flutter/material.dart';
import 'package:raffle_fox/pages/cart_screen.dart';
import 'package:raffle_fox/pages/shop_screen.dart';
import 'package:raffle_fox/pages/userProfile_screen.dart';
import 'package:provider/provider.dart';
import 'package:raffle_fox/providers/nav_bar_provider.dart';
 // Import the provider

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navBarProvider = Provider.of<NavBarProvider>(context);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFF15B29),
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: navBarProvider.currentIndex,
      onTap: (index) {
        navBarProvider.setCurrentIndex(index);  // Update the provider state
        _navigateToScreen(index, context);
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          activeIcon: Icon(Icons.favorite),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events),
          activeIcon: Icon(Icons.list_alt),
          label: '',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: '',
        ),
      ],
    );
  }

  void _navigateToScreen(int index, BuildContext context) {
    // Navigate based on the selected index
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ShopScreen()),
      );
    }
    else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CartScreen()),
      );
    }
    else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserProfileScreen()),
      );
    }
  }
}

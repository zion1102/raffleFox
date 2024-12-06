import 'package:flutter/material.dart';
import 'package:raffle_fox/widgets/BottomNavBar.dart';
import 'package:raffle_fox/widgets/Categories.dart';
import 'package:raffle_fox/widgets/EndingSoon.dart';
import 'package:raffle_fox/widgets/LatestRaffles.dart';
import 'package:raffle_fox/widgets/MainBanner.dart';
import 'package:raffle_fox/widgets/MostPopular.dart';
import 'package:raffle_fox/widgets/ProfileAppBar.dart';
import 'package:raffle_fox/widgets/TopRaffles.dart';
import 'package:raffle_fox/widgets/SearchBar.dart';
import 'package:raffle_fox/widgets/YourFavorites.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Simulate loading data for each widget
    await Future.delayed(const Duration(seconds: 2)); // Simulate a network request
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPage() async {
    setState(() {
      _isLoading = true;
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back navigation
      child: Scaffold(
        appBar: const ProfileAppBar(),
        body: Stack(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              RefreshIndicator(
                onRefresh: _refreshPage, // Pull-to-refresh action
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(), // Ensure scrollable even if content fits
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 70.0), // Avoid overlap with BottomNavBar
                    child: Column(
                      children: const [
                        MainBanner(),
                        SizedBox(height: 35),
                        SearchBarElement(),
                        SizedBox(height: 35),
                        TopRaffles(),
                        SizedBox(height: 45),
                        LatestRaffles(),
                        SizedBox(height: 35),
                        EndingSoon(),
                        SizedBox(height: 35),
                        MostPopular(),
                        SizedBox(height: 35),
                        YourFavorites(),
                        SizedBox(height: 35),
                        CategoriesSection(),
                      ],
                    ),
                  ),
                ),
              ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavBar(),
            ),
          ],
        ),
      ),
    );
  }
}

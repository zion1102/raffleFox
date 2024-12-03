import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:raffle_fox/blocs/guess/guess_bloc.dart';
import 'package:raffle_fox/pages/userProfile_screen.dart';
import 'package:raffle_fox/widgets/BottomNavBar.dart';
import 'package:raffle_fox/widgets/ProfileAppBar.dart';
import 'package:raffle_fox/widgets/ProgressBar.dart';
import 'package:raffle_fox/services/firebase_services.dart';
import 'package:raffle_fox/services/raffle_ticket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:raffle_fox/services/cart_service.dart';

class PickSpotScreen extends StatelessWidget {
  final Map<String, dynamic> raffleData;

  const PickSpotScreen({super.key, required this.raffleData});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GuessBloc(),
      child: PickSpotScreenContent(raffleData: raffleData),
    );
  }
}

class PickSpotScreenContent extends StatefulWidget {
  final Map<String, dynamic> raffleData;

  const PickSpotScreenContent({super.key, required this.raffleData});

  @override
  _PickSpotScreenContentState createState() => _PickSpotScreenContentState();
}

class _PickSpotScreenContentState extends State<PickSpotScreenContent> {
  Offset _dottedCirclePosition = const Offset(0, 0);
  Offset _imageCenter = const Offset(0, 0);
  Offset _pendingSpot = const Offset(0, 0);
  final List<Offset> _confirmedSpots = [];
  bool _isDragging = false;
  int remainingGuesses = 0;
  int availableCredits = 0;
  bool _isGuessConfirmed = false;
  final FirebaseService _firebaseService = FirebaseService();
  final RaffleTicketService _raffleTicketService = RaffleTicketService();
  final ScrollController _scrollController = ScrollController();
  final Color _darkerOrange = const Color(0xFFFF5F00);
  final CartService _cartService = CartService();
  late GuessBloc _guessBloc;

  @override
  void initState() {
    super.initState();
    _guessBloc = GuessBloc(); 
    _fetchUserCredits();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        final RenderBox imageBox = context.findRenderObject() as RenderBox;
        final imageSize = imageBox.size;
        _imageCenter = Offset(imageSize.width / 2, imageSize.height / 2);
        _dottedCirclePosition = _imageCenter;
      });
    });
  }

  Future<void> _fetchUserCredits() async {
    final userData = await _firebaseService.getUserDetails();
    if (userData != null) {
      setState(() {
        availableCredits = userData['credits'] ?? 0;
        remainingGuesses = (availableCredits / widget.raffleData['costPer']).floor();
      });
    }
  }

  Future<void> _saveRaffleTickets() async {
  try {
    final user = await _firebaseService.getUserDetails();
    if (user == null) {
      print("Error: No user found.");
      return;
    }
    final String userId = user['uid'];
    final String raffleId = widget.raffleData['raffleId'];
    final String raffleTitle = widget.raffleData['title'];
    final DateTime expiryDate = widget.raffleData['expiryDate'].toDate();
    final double costPer = (widget.raffleData['costPer'] as num).toDouble();
    final double totalPrice = costPer * _confirmedSpots.length;

    for (var spot in _confirmedSpots) {
      await _raffleTicketService.createRaffleTicket(
        raffleId: raffleId,
        userId: userId,
        raffleTitle: raffleTitle,
        expiryDate: expiryDate,
        xCoord: spot.dx,
        yCoord: spot.dy,
        price: costPer, // Single ticket price
      );
    }
    print("All raffle tickets saved successfully with total price: $totalPrice");
  } catch (e) {
    print("Error saving raffle tickets: $e");
  }
}

Future<void> _addConfirmedSpotsToCart() async {
  final user = await _firebaseService.getUserDetails();
  if (user == null) {
    print("Error: No user found.");
    return;
  }

  final String userId = user['uid'];
  final String raffleId = widget.raffleData['raffleId'];
  final String raffleTitle = widget.raffleData['title'];
  final DateTime expiryDate = widget.raffleData['expiryDate'].toDate();
  final double costPer = (widget.raffleData['costPer'] as num).toDouble();
  final double totalPrice = costPer * _confirmedSpots.length;

  for (var spot in _confirmedSpots) {
    await _cartService.addGuessToCart(
      raffleId: raffleId,
      userId: userId,
      raffleTitle: raffleTitle,
      expiryDate: expiryDate,
      xCoord: spot.dx,
      yCoord: spot.dy,
      price: costPer, // Single ticket price
    );
  }

  print("Position(s) added to cart with total price: $totalPrice");
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Postion(s) Added'),
      content: Text('${_confirmedSpots.length} position(s) added to your cart with total price: $totalPrice'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

void _confirmGuess() async {
  int totalGuesses = _confirmedSpots.length + 1;
  double costPer = (widget.raffleData['costPer'] as num).toDouble(); // Safely convert

  bool enoughCredits = await _raffleTicketService.hasEnoughCredits(
    totalGuesses,
    availableCredits, // int
    costPer, // double
  );

  if (!enoughCredits) {
    _showErrorDialog(
      'Oops! Looks like you don’t have enough credit. 😬',
      'You can delete your position(s) or add more credit to make sure you can play.',
    );
    return;
  }

  context.read<GuessBloc>().add(AddGuess(_dottedCirclePosition)); // Add guess to Bloc

  setState(() {
    _dottedCirclePosition = _imageCenter;
    remainingGuesses--;
    _isGuessConfirmed = true;
  });

  _showConfirmDialog();
}

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Are you sure? '),
          content: const Text('If you are, go ahead and confirm your position.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Change my position'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _confirmedSpots.add(_pendingSpot);
                  remainingGuesses--;
                  _dottedCirclePosition = _imageCenter;
                  _isGuessConfirmed = true;
                });
              },
              child: const Text('Yeah! I got skills'),
            ),
          ],
        );
      },
    );
  }

  void _showAddToCartConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save For Later'),
          content: const Text('Are you sure you want to save these position(s) to your cart?'),
          actions: [
             TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addConfirmedSpotsToCart();
              },
              child: const Text('Yes!'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Change my spot(s)'),
            ),
           
          ],
        );
      },
    );
  }

  

  void _showContinueConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Checkout'),
          content: const Text('Are you sure you want to continue to checkout with your confirmed position(s)?'),
          actions: [
             TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _onContinue();
              },
              child: const Text('Checkout'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Change my position(s)'),
            ),
           
          ],
        );
      },
    );
  }

  void _onContinue() async {
    if (_confirmedSpots.isEmpty) {
      _showErrorDialog('Aaahh looks like you have no more position(s) 🤷', 'But, never fear, you can always get more and give yourself the best odds. ');
      return;
    }

   bool enoughCredits = await _raffleTicketService.hasEnoughCredits(
    _confirmedSpots.length,
    availableCredits,
    (widget.raffleData['costPer'] as num).toDouble(), // Convert here
);

    if (!enoughCredits) {
      _showErrorDialog(
        'Oops! Looks like you don’t have enough credit. 😬',
        'You do not have enough credits to save all your position(s). Please remove position(s) or add more credits.',
      );
      return;
    }

    await _saveRaffleTickets();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UserProfileScreen(),
      ),
    );
  }

 void _showErrorDialog(String title, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final url = Uri.parse('https://rafflefox.netlify.app/');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      throw 'Could not launch $url';
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkerOrange, // Use the same orange color
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Payment Portal',
                    style: TextStyle(
                      color: Colors.white, // Text color
                      decoration: TextDecoration.none,
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Placeholder for Apple Pay functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Apple Pay typical black color
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Apple Pay',
                    style: TextStyle(
                      color: Colors.white, // Text color
                      decoration: TextDecoration.none,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

@override
  Widget build(BuildContext context) {
    return BlocBuilder<GuessBloc, GuessState>(
      builder: (context, state) {
        List<Offset> confirmedSpots = [];
        if (state is GuessUpdated) {
          confirmedSpots = state.confirmedSpots;
        }

        return Scaffold(
          appBar: const ProfileAppBar(),
          body: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                physics: _isDragging
                    ? const NeverScrollableScrollPhysics()
                    : const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pick a Spot",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.raffleData['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 30),
                    CustomProgressBar(
                      progress: 0.5,
                      progressColor: _darkerOrange,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xfff8f8f8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Select a target on the image",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                "Drag your finger to place the prize target",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          if (_isGuessConfirmed)
                            CircleAvatar(
                              backgroundColor: _darkerOrange,
                              child: const Icon(Icons.check, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              GestureDetector(
                                onTapDown: (details) => _onTapDown(details, const Size(352, 492)),
                                onPanUpdate: (details) => _onDragUpdate(details, const Size(352, 492)),
                                onPanEnd: (_) => setState(() => _isDragging = false),
                                child: Image.network(
                                  widget.raffleData['editedGamePicture'],
                                  width: 352,
                                  height: 492,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                left: _dottedCirclePosition.dx - 24,
                                top: _dottedCirclePosition.dy - 24,
                                child: Image.asset(
                                  "assets/images/dotted.png",
                                  width: 48,
                                  height: 48,
                                ),
                              ),
                              ...confirmedSpots.map(
                                (spot) => Positioned(
                                  left: spot.dx - 24,
                                  top: spot.dy - 24,
                                  child: GestureDetector(
                                    onLongPress: () =>
                                        context.read<GuessBloc>().add(RemoveGuess(spot)),
                                    child: Image.asset(
                                      "assets/images/guessCircle.png",
                                      width: 48,
                                      height: 48,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Coordinates: (${_dottedCirclePosition.dx.toStringAsFixed(1)}, ${_dottedCirclePosition.dy.toStringAsFixed(1)})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
ElevatedButton(
  onPressed: _isGuessConfirmed ? _showAddToCartConfirmationDialog : null,
  style: ElevatedButton.styleFrom(
    backgroundColor: _darkerOrange,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
  ),
  child: const Text(
    'Save For Later',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
  ),
),
const SizedBox(height: 20),
ElevatedButton(
  onPressed: _isGuessConfirmed ? _showContinueConfirmationDialog : null,
  style: ElevatedButton.styleFrom(
    backgroundColor: _darkerOrange,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  ),
  child: const Text(
    'Checkout',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
  ),
),
const SizedBox(height: 20),
ElevatedButton(
                            onPressed: _confirmGuess,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _darkerOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 12),
                            ),
                            child: const Text(
                              'Confirm This Position',
                              style: TextStyle( 
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: const BottomNavBar(),
        );
      },
    );
  }

  void _onTapDown(TapDownDetails details, Size imageSize) {
    setState(() {
      double x = details.localPosition.dx.clamp(0, imageSize.width);
      double y = details.localPosition.dy.clamp(0, imageSize.height);
      _dottedCirclePosition = Offset(x, y);
    });
  }

  void _onDragUpdate(DragUpdateDetails details, Size imageSize) {
    setState(() {
      double x = details.localPosition.dx.clamp(0, imageSize.width);
      double y = details.localPosition.dy.clamp(0, imageSize.height);
      _dottedCirclePosition = Offset(x, y);
    });
  }

  void _showDeleteDialog(Offset spot) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete Guess'),
        content: const Text('Are you sure you want to delete this guess?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _confirmedSpots.remove(spot);
                remainingGuesses++;
                
                // Set _isGuessConfirmed based on whether there are confirmed spots left
                _isGuessConfirmed = _confirmedSpots.isNotEmpty;
              });
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}

}

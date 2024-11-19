import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:raffle_fox/services/firebase_services.dart';
import 'package:raffle_fox/services/raffle_service.dart';
import 'package:raffle_fox/widgets/CreatorBottomNavBar.dart';
import 'package:raffle_fox/widgets/ProfileAppBar.dart';
import 'package:image/image.dart' as img;

class CreateRaffleScreen extends StatefulWidget {
  const CreateRaffleScreen({super.key});

  @override
  _CreateRaffleScreenState createState() => _CreateRaffleScreenState();
}

class _CreateRaffleScreenState extends State<CreateRaffleScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController detail1Controller = TextEditingController();
  final TextEditingController detail2Controller = TextEditingController();
  final TextEditingController detail3Controller = TextEditingController();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  DateTime? startDate;
  DateTime? endDate;
  File? pictureFile;
  File? editedGamePictureFile;
  File? uneditedGamePictureFile;

  final RaffleService _raffleService = RaffleService();
  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();

  String? selectedCategory;
  String? selectedTier;
  double? selectedPrice;

  final List<String> categories = [
    'Lifestyle',
    'Entertainment',
    'Devices',
    'Electronics',
    'Style',
    'Beauty & Grooming'
  ];
  final List<String> tiers = ['Tier 1', 'Tier 2', 'Tier 3', 'Tier 4'];

  // Updated price mappings for each category and tier
  final Map<String, Map<String, double>> priceMap = {
    'Lifestyle': {'Tier 1': 500.0, 'Tier 2': 1000.0, 'Tier 3': 1500.0, 'Tier 4': 2000.0},
    'Entertainment': {'Tier 1': 100.0, 'Tier 2': 300.0, 'Tier 3': 500.0, 'Tier 4': 700.0},
    'Devices': {'Tier 1': 300.0, 'Tier 2': 600.0, 'Tier 3': 900.0, 'Tier 4': 1200.0},
    'Electronics': {'Tier 1': 200.0, 'Tier 2': 500.0, 'Tier 3': 800.0, 'Tier 4': 1000.0},
    'Style': {'Tier 1': 50.0, 'Tier 2': 100.0, 'Tier 3': 150.0, 'Tier 4': 200.0},
    'Beauty & Grooming': {'Tier 1': 20.0, 'Tier 2': 50.0, 'Tier 3': 80.0, 'Tier 4': 100.0},
  };

  Future<File?> compressImage(File file) async {
    final image = img.decodeImage(file.readAsBytesSync());
    final resizedImage = img.copyResize(image!, width: 800);
    final compressedBytes = img.encodeJpg(resizedImage, quality: 80);
    final tempDir = await getTemporaryDirectory();
    final compressedFile = File('${tempDir.path}/compressed_image.jpg')..writeAsBytesSync(compressedBytes);
    return compressedFile;
  }

  Future<void> _pickImage(bool isEditedImage, bool isPrimaryImage) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File? imageFile = File(pickedFile.path);
      imageFile = await compressImage(imageFile);
      setState(() {
        if (isPrimaryImage) {
          pictureFile = imageFile;
        } else if (isEditedImage) {
          editedGamePictureFile = imageFile;
        } else {
          uneditedGamePictureFile = imageFile;
        }
      });
    }
  }

  Future<void> _pickDate(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          startDate = pickedDate;
        } else {
          endDate = pickedDate;
        }
      });
    }
  }

  void _updatePrice() {
    if (selectedCategory != null && selectedTier != null) {
      setState(() {
        selectedPrice = priceMap[selectedCategory!]?[selectedTier!];
      });
    }
  }

  void _showCategoryDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: categories.map((category) {
            return ListTile(
              title: Text(
                category,
                style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                setState(() {
                  selectedCategory = category;
                  _updatePrice();
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showTierDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          children: tiers.map((tier) {
            return ListTile(
              title: Text(
                tier,
                style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                setState(() {
                  selectedTier = tier;
                  _updatePrice();
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showConfirmationDialog() async {
    if (selectedCategory != null && selectedTier != null && selectedPrice != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Raffle Creation'),
          content: Text(
              'You have selected:\nCategory: $selectedCategory\nTier: $selectedTier\nPrice per ticket: \$${selectedPrice!.toStringAsFixed(2)}\n\nDo you want to proceed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _createRaffle();
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    } else {
      _showErrorDialog('Please select a category and tier before proceeding.');
    }
  }

  void _createRaffle() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      // Check if user is authorized
      String? userType = await _firebaseService.getUserType(uid);

      if (userType != 'creator') {
        throw Exception("You are not authorized to create a raffle.");
      }

      // Show creation progress
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creating raffle...')),
      );

      // Upload images
      final primaryImageRef = _storage.ref().child('raffle_images/$uid/primary.jpg');
      await primaryImageRef.putFile(pictureFile!);
      final primaryImageUrl = await primaryImageRef.getDownloadURL();

      await _raffleService.addRaffle(
        title: nameController.text,
        description: descriptionController.text,
        expiryDate: endDate!,
        category: selectedCategory!,
        costPer: selectedPrice!,
        pictureFile: pictureFile!,
        editedGamePictureFile: editedGamePictureFile!,
        uneditedGamePictureFile: uneditedGamePictureFile!,
        creatorId: uid,
        raffleId: DateTime.now().millisecondsSinceEpoch.toString(),
        ticketsSold: 0,
        detailOne: detail1Controller.text,
        detailTwo: detail2Controller.text,
        detailThree: detail3Controller.text,
      );

      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Raffle created successfully!')),
      );
      _clearFields();
    } catch (e) {
      print("Error creating raffle: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create raffle: $e')),
      );
    }
  }

  void _clearFields() {
    setState(() {
      nameController.clear();
      descriptionController.clear();
      detail1Controller.clear();
      detail2Controller.clear();
      detail3Controller.clear();
      startDate = null;
      endDate = null;
      pictureFile = null;
      editedGamePictureFile = null;
      uneditedGamePictureFile = null;
      selectedCategory = null;
      selectedTier = null;
      selectedPrice = null;
    });
  }

  bool _validateFields() {
    if (selectedCategory == null ||
        selectedTier == null ||
        startDate == null ||
        endDate == null ||
        pictureFile == null ||
        editedGamePictureFile == null ||
        uneditedGamePictureFile == null) {
      _showErrorDialog('Please fill all required fields.');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ProfileAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create a Raffle",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text("Primary Raffle Image"),
            GestureDetector(
              onTap: () => _pickImage(false, true),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                  image: pictureFile != null
                      ? DecorationImage(
                          image: FileImage(pictureFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: pictureFile == null
                    ? const Center(child: Icon(Icons.add_a_photo, color: Colors.white, size: 50))
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Edited Game Image"),
                      GestureDetector(
                        onTap: () => _pickImage(true, false),
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[300],
                            image: editedGamePictureFile != null
                                ? DecorationImage(
                                    image: FileImage(editedGamePictureFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: editedGamePictureFile == null
                              ? const Center(child: Icon(Icons.add_photo_alternate, color: Colors.white, size: 50))
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Unedited Game Image"),
                      GestureDetector(
                        onTap: () => _pickImage(false, false),
                        child: Container(
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[300],
                            image: uneditedGamePictureFile != null
                                ? DecorationImage(
                                    image: FileImage(uneditedGamePictureFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: uneditedGamePictureFile == null
                              ? const Center(child: Icon(Icons.image, color: Colors.white, size: 50))
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _showCategoryDropdown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedCategory ?? "Select a Category",
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedCategory == null ? Colors.grey : Colors.black,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.deepOrange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showTierDropdown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedTier ?? "Select a Tier",
                      style: TextStyle(
                        fontSize: 16,
                        color: selectedTier == null ? Colors.grey : Colors.black,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.deepOrange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (selectedPrice != null)
              Text(
                "Price: \$${selectedPrice!.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        startDate != null ? DateFormat('yyyy-MM-dd').format(startDate!) : "Start Date",
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : "End Date",
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Raffle Name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: detail1Controller,
              decoration: const InputDecoration(labelText: "Detail 1"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: detail2Controller,
              decoration: const InputDecoration(labelText: "Detail 2"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: detail3Controller,
              decoration: const InputDecoration(labelText: "Detail 3"),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  if (_validateFields()) {
                    _showConfirmationDialog();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                  shadowColor: Colors.orangeAccent,
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CreatorBottomNavBar(selectedIndex: 1),
    );
  }
}

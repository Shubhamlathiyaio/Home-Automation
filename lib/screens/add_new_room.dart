import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/homepage.dart';
import '../widgets/bottom_nav_bar.dart';

class AddNewRoom extends StatefulWidget {
  final String areaName;
  final String phoneNumber;

  const AddNewRoom({
    super.key,
    required this.areaName,
    required this.phoneNumber,
  });

  @override
  State<AddNewRoom> createState() => _AddNewRoomState();
}

class _AddNewRoomState extends State<AddNewRoom> {
  final TextEditingController roomNameController = TextEditingController();
  String selectedImage = 'assets/rooms/bedroom.jpg';
  bool isLoading = false;
  bool isCustomRoom = false;
  File? customImageFile;
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, String>> availableImages = [
    {'name': 'Bedroom', 'path': 'assets/rooms/bedroom.jpg'},
    {'name': 'Living Room', 'path': 'assets/rooms/LivingRoom.jpg'},
    {'name': 'Kitchen', 'path': 'assets/rooms/kitchen.jpg'},
    {'name': 'Bathroom', 'path': 'assets/rooms/bathrooms.jpg'},
    {'name': 'Office', 'path': 'assets/rooms/office.jpg'},
    {'name': 'Dining Room', 'path': 'assets/rooms/dining.jpg'},
  ];

  @override
  void initState() {
    super.initState();
    roomNameController.text = 'Bedroom';
  }

  Future<void> _showCustomRoomDialog() async {
    final TextEditingController customNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Custom Room',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: customNameController,
                    decoration: InputDecoration(
                      labelText: 'Room Name',
                      hintText: 'Enter room name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.room_preferences),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (customImageFile != null)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.25,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          customImageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 70,
                        maxWidth: 1024,
                        maxHeight: 1024,
                      );
                      if (image != null) {
                        setState(() {
                          customImageFile = File(image.path);
                        });
                        if (mounted) {
                          Navigator.pop(context);
                          _showCustomRoomDialog(); // Reopen dialog to show selected image
                        }
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(customImageFile == null
                        ? 'Select Image'
                        : 'Change Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3436),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isCustomRoom = false;
                            customImageFile = null;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final name = customNameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter a room name')),
                            );
                            return;
                          }
                          if (customImageFile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please select an image')),
                            );
                            return;
                          }
                          setState(() {
                            isCustomRoom = true;
                            roomNameController.text = name;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D3436),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    roomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Add New Room',
          style: TextStyle(
            color: Color(0xFF2D3436),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showCustomRoomDialog,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Custom Room'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2D3436),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCustomRoom && customImageFile != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2D3436),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Image.file(
                        customImageFile!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                          onPressed: _showCustomRoomDialog,
                          icon: const Icon(Icons.edit, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF2D3436),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: roomNameController,
                decoration: InputDecoration(
                  labelText: 'Room Name',
                  hintText: 'Enter room name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.room_preferences),
                ),
              ),
            ] else ...[
              const Text(
                'Select Room Type:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: availableImages.length,
                itemBuilder: (context, index) {
                  final image = availableImages[index];
                  bool isSelected =
                      !isCustomRoom && selectedImage == image['path'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        isCustomRoom = false;
                        selectedImage = image['path']!;
                        roomNameController.text = image['name']!;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2D3436)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                              child: Image.asset(
                                image['path']!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              image['name']!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _addRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3436),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Add Room',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: 1,
        phoneNumber: widget.phoneNumber,
        areaName: widget.areaName,
      ),
    );
  }

  Future<void> _addRoom() async {
    final roomName = roomNameController.text.trim();
    if (roomName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a room name')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Check if room already exists
      final roomRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(widget.phoneNumber)
          .child('Infrastructure')
          .child(widget.areaName)
          .child(roomName);

      final snapshot = await roomRef.get();
      if (snapshot.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('A room with this name already exists')),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      String imageUrl;
      if (isCustomRoom && customImageFile != null) {
        // Upload image to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('room_images')
            .child(widget.phoneNumber)
            .child(
                '${DateTime.now().millisecondsSinceEpoch}_${roomName.toLowerCase().replaceAll(' ', '_')}.jpg');

        // Create upload task with metadata
        final uploadTask = storageRef.putFile(
          customImageFile!,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'roomName': roomName,
              'timestamp': DateTime.now().toIso8601String(),
              'isCustom': 'true',
            },
          ),
        );

        // Wait for upload to complete
        await uploadTask.whenComplete(() {});

        // Get download URL
        imageUrl = await storageRef.getDownloadURL();
      } else {
        imageUrl = selectedImage;
      }

      // Add room to Firebase Database with proper structure
      Map<String, dynamic> roomData = {
        'Device': {},
        'image': imageUrl,
        'isCustom': isCustomRoom,
        'name': roomName,
        'timestamp': ServerValue.timestamp,
      };

      // Add room data
      await roomRef.set(roomData);

      // Wait a bit to ensure data is properly saved
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() => isLoading = false);

      if (mounted) {
        // Navigate back to homepage and refresh
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => Homepage(number: widget.phoneNumber),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding room: $e');
      } // Add debug print
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding room: $e')),
        );
      }
    }
  }
}

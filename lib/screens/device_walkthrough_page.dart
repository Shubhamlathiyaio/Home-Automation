import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class DeviceWalkthroughPage extends StatefulWidget {
  const DeviceWalkthroughPage({super.key});

  @override
  State<DeviceWalkthroughPage> createState() => _DeviceWalkthroughPageState();
}

class _DeviceWalkthroughPageState extends State<DeviceWalkthroughPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Scan QR Code',
      'description':
          'First, scan the QR code on your device to begin the setup process.',
      'animation': 'assets/Lottie/scan_qr.json',
      'action': 'Next',
    },
    {
      'title': 'Select Room',
      'description': 'Choose the room where you want to add your device.',
      'animation': 'assets/Lottie/rooms.json',
      'action': 'Next',
    },
    {
      'title': 'Select Device Type',
      'description':
          'Pick the type of device you\'re adding from the available options.',
      'animation': 'assets/Lottie/device.json',
      'action': 'Next',
    },
    {
      'title': 'All Set!',
      'description':
          'Your device is now ready to use. You can control it from the app.',
      'animation': 'assets/Lottie/done.json',
      'action': 'Finish',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == _steps.length - 1) {
      Navigator.pop(context);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('How to Add Device'),
        backgroundColor: const Color(0xFF2D3436),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        step['animation'],
                        height: 200,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Step ${index + 1}: ${step['title']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        step['description'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Page Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _steps.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? const Color(0xFF2D3436)
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Action Button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3436),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _steps[_currentPage]['action'],
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

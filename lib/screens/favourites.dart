import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_home/devices/Fan/fan_page.dart';
import 'package:smart_home/devices/RGB/rgb_page.dart';
import 'package:smart_home/main.dart';
import 'package:smart_home/model/device_model.dart';
import 'package:smart_home/model/firebase_model.dart';
import 'package:smart_home/screens/scheduled_page.dart';
import '../widgets/bottom_nav_bar.dart';

class FavouritePage extends StatefulWidget {
  final String areaName;
  final String phoneNumber;

  const FavouritePage({
    Key? key,
    required this.areaName,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  bool isLoading = false;
  List<DeviceModel> _favoriteDevices = [];
  FirebaseModel fire = FirebaseModel();

  @override
  void initState() {
    super.initState();
    fetchFavoriteDevices();
  }

  Future<void> fetchFavoriteDevices() async {
    setState(() => isLoading = true);
    fire.devices.clear();

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$phoneNumber/Infrastructure/${widget.areaName}')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final roomsData = snapshot.value as Map<dynamic, dynamic>;

        for (var roomData in roomsData.entries) {
          final roomName = roomData.key.toString();
          final roomValue = roomData.value;

          if (roomValue is Map && roomValue['Device'] is Map) {
            final devicesData = roomValue['Device'] as Map<dynamic, dynamic>;

            devicesData.forEach((deviceId, deviceData) {
              if (deviceData is Map) {
                try {
                  // Create a safe copy of the device data
                  Map<String, dynamic> deviceMap = {
                    'electronicType': deviceData['electronicType'],
                    'isOn': deviceData['isOn'] ?? 0,
                    'value': deviceData['value']?.toString() ?? '0',
                    'isFavorite': deviceData['isFavorite'] ?? 0,
                    'roomName': roomName,
                  };

                  // Add image to the device data
                  deviceMap['image'] =
                      getDeviceImage(deviceMap['electronicType'] ?? '');

                  // Create device model
                  DeviceModel device =
                      DeviceModel.fromMap(deviceId.toString(), deviceMap);
                  fire.devices.add(device);
                } catch (e) {
                  if (kDebugMode) {
                    print('Error processing device $deviceId: $e');
                  }
                }
              }
            });
          }
        }

        if (mounted) {
          setState(() {
            _favoriteDevices =
                fire.devices.where((device) => device.isFavorite).toList();
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _favoriteDevices = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading favorites: $e');
      }
      if (mounted) {
        setState(() {
          _favoriteDevices = [];
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with animated gradient
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF2D3436),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context, 'true'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Favorites',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2D3436),
                          Colors.blue.shade900,
                          Colors.purple.shade900,
                        ],
                      ),
                    ),
                  ),
                  // Animated pattern overlay
                  CustomPaint(
                    painter: CirclePatternPainter(),
                  ),
                ],
              ),
            ),
          ),

          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2D3436),
                ),
              ),
            )
          else if (_favoriteDevices.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star_border_rounded,
                        size: 64,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Favorite Devices',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Add devices to your favorites to quickly access them here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildDeviceCard(_favoriteDevices[index]),
                  childCount: _favoriteDevices.length,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: 1,
        phoneNumber: widget.phoneNumber,
        areaName: widget.areaName,
      ),
    );
  }

  Widget _buildDeviceCard(DeviceModel device) {
    return GestureDetector(
      onTap: () async {
        switch (device.electronicType) {
          case 'Fan':
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FanPage(
                  id: device.id,
                  areaName: widget.areaName,
                ),
              ),
            );

            if (result != null && mounted) {
              setState(() {
                final index = devices.indexWhere((d) => d.id == result['id']);
                if (index != -1) {
                  devices[index].isOn = result['isOn'];
                  devices[index].value = result['value'];
                  devices[index].isFavorite = result['isFavorite'];
                }
              });
            }
            break;

          case 'RGB Light':
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RGBPage(
                  id: device.id,
                  areaName: widget.areaName,
                ),
              ),
            );

            if (result != null && mounted) {
              setState(() {
                final index = devices.indexWhere((d) => d.id == result['id']);
                if (index != -1) {
                  devices[index].isOn = result['isOn'];
                  devices[index].value = result['value'];
                  devices[index].isFavorite = result['isFavorite'];
                }
              });
            }
            break;

          default:
            // For all other devices, open the schedule page directly
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ScheduledPage(
                  electronicType: device.electronicType,
                  roomName: device.roomName,
                  deviceId: device.id,
                  areaName: widget.areaName,
                ),
              ),
            );
            break;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: device.isOn ? const Color(0xFF2D3436) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              device.image,
              height: 48,
              color: device.isOn ? Colors.white : const Color(0xFF2D3436),
            ),
            const SizedBox(height: 16),
            Text(
              device.electronicType,
              style: TextStyle(
                color: device.isOn ? Colors.white : const Color(0xFF2D3436),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              device.roomName,
              style: TextStyle(
                color: device.isOn
                    ? Colors.white.withOpacity(0.7)
                    : const Color(0xFF2D3436).withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    device.isFavorite ? Icons.star : Icons.star_border,
                    color: device.isFavorite
                        ? Colors.amber
                        : device.isOn
                            ? Colors.white
                            : const Color(0xFF2D3436),
                  ),
                  onPressed: () async {
                    setState(() {
                      device.isFavorite = !device.isFavorite;
                    });
                    await fire.boolUpdateFav(device, widget.areaName);
                    // Refresh the favorites list
                    if (!device.isFavorite) {
                      setState(() {
                        _favoriteDevices.remove(device);
                      });
                    }
                  },
                ),
                Switch.adaptive(
                  value: device.isOn,
                  onChanged: (value) {
                    setState(() => device.isOn = value);
                    fire.updateTime(device, device.roomName, widget.areaName);
                    fire.boolUpdateOn(device, device.roomName, widget.areaName);
                  },
                  activeColor: Colors.white,
                  activeTrackColor: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double maxRadius = size.width * 0.8;
    final center = Offset(size.width * 0.5, size.height * 0.3);

    for (double radius = 20; radius < maxRadius; radius += 20) {
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

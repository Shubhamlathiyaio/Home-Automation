import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_home/main.dart';
import 'package:smart_home/model/device_model.dart';
import 'package:smart_home/model/firebase_model.dart';
import 'package:smart_home/screens/scheduled_page.dart';

class FanPage extends StatefulWidget {
  final String id;
  final String areaName;

  const FanPage({
    super.key,
    required this.id,
    required this.areaName,
  });

  @override
  State<FanPage> createState() => _FanPageState();
}

class _FanPageState extends State<FanPage> with TickerProviderStateMixin {
  DeviceModel? device;
  bool isLoading = true;
  int fanSpeedLevel = 0;
  FirebaseModel fire = FirebaseModel();
  late AnimationController _fanController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  Timer? _scheduleTimer;

  @override
  void initState() {
    super.initState();
    _fanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _fetchDeviceData();

    // Start schedule checker
    _scheduleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        fire.checkAndUpdateSchedule(
          widget.areaName,
          device?.roomName ?? '',
          widget.id,
        );
      }
    });
  }

  @override
  void dispose() {
    _scheduleTimer?.cancel();
    _fanController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeviceData() async {
    try {
      DatabaseEvent event = await FirebaseDatabase.instance
          .ref('users/$phoneNumber/Infrastructure/${widget.areaName}')
          .once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;

        for (var room in data.entries) {
          if (room.value is Map && room.value['Device'] is Map) {
            Map devices = room.value['Device'];
            if (devices.containsKey(widget.id)) {
              Map deviceData = devices[widget.id];
              deviceData['roomName'] = room.key;
              deviceData['id'] = widget.id;
              deviceData['image'] =
                  getDeviceImage(deviceData['electronicType']);

              setState(() {
                device = DeviceModel.fromMap(
                    widget.id, Map<String, dynamic>.from(deviceData));
                fanSpeedLevel = int.parse(device?.value ?? '0');
                isLoading = false;

                if (device!.isOn) {
                  _fanController.duration =
                      Duration(milliseconds: 2000 - (fanSpeedLevel * 300));
                  _fanController.repeat();
                  _scaleController.forward();
                }
              });
              break;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching device: $e');
      }
      setState(() => isLoading = false);
    }

    _listenToDeviceChanges();
  }

  void _updateFanState(bool isOn) {
    setState(() {
      device!.isOn = isOn;
      if (isOn) {
        if (fanSpeedLevel == 0) {
          fanSpeedLevel = 1;
          device!.value = '1';
        }
        _fanController.repeat();
        _scaleController.forward();
      } else {
        fanSpeedLevel = 0;
        device!.value = '0';
        _fanController.stop();
        _scaleController.reverse();
      }
    });

    fire.boolUpdateOn(device!, device!.roomName, widget.areaName);

    FirebaseDatabase.instance
        .ref('users/$phoneNumber/Infrastructure')
        .child(widget.areaName)
        .child(device!.roomName)
        .child('Device')
        .child(device!.id)
        .update({
      'value': device!.value,
      'isOn': device!.isOn ? 1 : 0,
    });
  }

  Widget _buildSpeedLevel(int level) {
    bool isSelected = fanSpeedLevel == level;
    return GestureDetector(
      onTap: device!.isOn ? () => _updateSpeed(level) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 60,
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D3436) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2D3436).withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: isSelected ? const Color(0xFF2D3436) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.air,
              size: 24,
              color: isSelected ? Colors.white : const Color(0xFF2D3436),
            ),
            const SizedBox(height: 8),
            Text(
              'Speed\n$level',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2D3436),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (device == null) {
      return const Scaffold(
        body: Center(child: Text('Device not found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Animated App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF2D3436),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context, {
                  'id': device!.id,
                  'isOn': device!.isOn,
                  'value': device!.value,
                  'isFavorite': device!.isFavorite,
                });
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                device!.electronicType,
                style: const TextStyle(color: Colors.white),
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
                        ],
                      ),
                    ),
                  ),
                  // Animated pattern overlay
                  CustomPaint(
                    painter: CirclePatternPainter(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return RotationTransition(
                      turns: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: Icon(
                    device!.isFavorite ? Icons.star : Icons.star_border,
                    key: ValueKey<bool>(device!.isFavorite),
                    color: Colors.yellow,
                  ),
                ),
                onPressed: () {
                  setState(() => device!.isFavorite = !device!.isFavorite);
                  fire.boolUpdateFav(device!, widget.areaName);
                },
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Lottie Animation with Scale
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Lottie.asset(
                      'assets/Lottie/fan.json',
                      controller: _fanController,
                      width: 250,
                      height: 250,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Controls Card
                Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Power Switch with Animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: device!.isOn
                              ? const Color(0xFF2D3436).withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            'Power',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          value: device!.isOn,
                          onChanged: _updateFanState,
                          activeColor: const Color(0xFF2D3436),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Fan Speed Text
                      Text(
                        'Fan Speed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: device!.isOn
                              ? const Color(0xFF2D3436)
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Speed Level Selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: List.generate(
                            5,
                            (index) => _buildSpeedLevel(index + 1),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Current Speed Indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: device!.isOn
                              ? const Color(0xFF2D3436)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          device!.isOn
                              ? 'Current Speed: $fanSpeedLevel'
                              : 'Fan is Off',
                          style: TextStyle(
                            color: device!.isOn ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Schedule Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3436),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.schedule),
                    label: const Text(
                      'Schedule',
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScheduledPage(
                            electronicType: device!.electronicType,
                            roomName: device!.roomName,
                            deviceId: device!.id,
                            areaName: widget.areaName,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateSpeed(int newSpeed) {
    setState(() {
      fanSpeedLevel = newSpeed;
      device!.value = newSpeed.toString();
    });

    FirebaseDatabase.instance
        .ref('users/$phoneNumber/Infrastructure')
        .child(widget.areaName)
        .child(device!.roomName)
        .child('Device')
        .child(device!.id)
        .update({'value': device!.value});

    _fanController.duration = Duration(milliseconds: 2000 - (newSpeed * 300));
    if (device!.isOn) {
      _fanController.repeat();
    }
  }

  // Add listener for real-time updates
  void _listenToDeviceChanges() {
    FirebaseDatabase.instance
        .ref(
            'users/$phoneNumber/Infrastructure/${widget.areaName}/${device!.roomName}/Device/${widget.id}')
        .onValue
        .listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          final isOn = (data['isOn'] ?? 0) == 1;
          final value = data['value']?.toString() ?? '0';

          device!.isOn = isOn;
          device!.value = value;
          fanSpeedLevel = int.parse(value);

          if (isOn) {
            _fanController.duration =
                Duration(milliseconds: 2000 - (fanSpeedLevel * 300));
            _fanController.repeat();
            _scaleController.forward();
          } else {
            _fanController.stop();
            _scaleController.reverse();
          }
        });
      }
    });
  }
}

class CirclePatternPainter extends CustomPainter {
  final Color color;

  CirclePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 5; i++) {
      final radius = size.width * (i + 1) / 10;
      canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.2),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

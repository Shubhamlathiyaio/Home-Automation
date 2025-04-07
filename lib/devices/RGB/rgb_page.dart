import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:smart_home/main.dart';
import 'package:smart_home/model/device_model.dart';
import 'package:smart_home/model/firebase_model.dart';
import 'package:smart_home/screens/scheduled_page.dart';

class RGBPage extends StatefulWidget {
  final String id;
  final String areaName;

  const RGBPage({
    super.key,
    required this.id,
    required this.areaName,
  });

  @override
  State<RGBPage> createState() => _RGBPageState();
}

class _RGBPageState extends State<RGBPage> with TickerProviderStateMixin {
  DeviceModel? device;
  bool isLoading = true;
  Color currentColor = Colors.blue;
  FirebaseModel fire = FirebaseModel();
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  Timer? _scheduleTimer;

  @override
  void initState() {
    super.initState();
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
                currentColor = _parseColor(device?.value ?? '#0000FF');
                isLoading = false;

                if (device!.isOn) {
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

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll("#", "");
      if (hexColor.length == 6) {
        return Color(int.parse("FF$hexColor", radix: 16));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing color: $e');
      }
    }
    return Colors.blue;
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _updateRGBState(bool isOn) {
    setState(() {
      device!.isOn = isOn;
      if (isOn) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
    });

    fire.boolUpdateOn(device!, device!.roomName, widget.areaName);
  }

  void _updateColor(Color color) {
    setState(() {
      currentColor = color;
      device!.value = _colorToHex(color);
    });

    FirebaseDatabase.instance
        .ref(
            'users/$phoneNumber/Infrastructure/${widget.areaName}/${device!.roomName}/Device')
        .child(device!.id)
        .update({'value': device!.value});
  }

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
          final value = data['value']?.toString() ?? '#0000FF';

          device!.isOn = isOn;
          device!.value = value;
          currentColor = _parseColor(value);

          if (isOn) {
            _scaleController.forward();
          } else {
            _scaleController.reverse();
          }
        });
      }
    });
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
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: currentColor,
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
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      currentColor,
                      currentColor.withOpacity(0.7),
                    ],
                  ),
                ),
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
                // Color Preview
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: device!.isOn ? currentColor : Colors.grey,
                        boxShadow: [
                          BoxShadow(
                            color: (device!.isOn ? currentColor : Colors.grey)
                                .withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Controls Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
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
                      // Power Switch
                      SwitchListTile(
                        title: const Text(
                          'Power',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: device!.isOn,
                        onChanged: _updateRGBState,
                        activeColor: currentColor,
                      ),

                      const SizedBox(height: 24),

                      // Color Picker
                      if (device!.isOn) ...[
                        const Text(
                          'Color',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ColorPicker(
                          pickerColor: currentColor,
                          onColorChanged: _updateColor,
                          enableAlpha: false,
                          displayThumbColor: true,
                          portraitOnly: true,
                        ),
                      ],
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
}

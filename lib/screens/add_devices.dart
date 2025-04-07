import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_home/main.dart';

class AddDevices extends StatefulWidget {
  final String roomName;
  final String areaName;

  const AddDevices({
    super.key,
    required this.roomName,
    required this.areaName,
  });

  @override
  State<AddDevices> createState() => _AddDevicesState();
}

class _AddDevicesState extends State<AddDevices> {
  final List<DeviceCategory> categories = [
    DeviceCategory(
      name: 'Lighting',
      devices: [
        Device('Ceiling Lamp', 'assets/appliances/lamp.svg'),
        Device('Lamp', 'assets/appliances/light.svg'),
        Device('RGB Light', 'assets/appliances/rgb-light.svg'),
        Device('Desk Light', 'assets/appliances/desk-light.svg'),
        Device('Bulb', 'assets/appliances/bulb.svg'),
      ],
    ),
    DeviceCategory(
      name: 'Climate',
      devices: [
        Device('Air Conditioner', 'assets/appliances/air-conditioner.svg'),
        Device('Fan', 'assets/appliances/ceiling-fan.svg'),
        Device('Table Fan', 'assets/appliances/table-fan.svg'),
        Device('Exhaust Fan', 'assets/appliances/cpu.svg'),
        Device('Cooler', 'assets/appliances/cooler.svg'),
      ],
    ),
    DeviceCategory(
      name: 'Appliances',
      devices: [
        Device('T.V.', 'assets/appliances/tv.svg'),
        Device('Refrigerator', 'assets/appliances/refrigerator.svg'),
        Device('Microwave', 'assets/appliances/microwave.svg'),
        Device('Washing Machine', 'assets/appliances/washing-machine.svg'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2D3436),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Add Device to ${widget.roomName}',
                style: const TextStyle(color: Colors.white),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/rooms/rooms.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, categoryIndex) {
                  final category = categories[categoryIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: category.devices.length,
                        itemBuilder: (context, deviceIndex) {
                          final device = category.devices[deviceIndex];
                          return GestureDetector(
                            onTap: () => _addDevice(device.name),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
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
                                    device.iconPath,
                                    height: 40,
                                    color: const Color(0xFF2D3436),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    device.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addDevice(String deviceType) async {
    if (widget.areaName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, color: Colors.white),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Please add a location first from drawer menu',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2D3436),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    String randomString = getRandomString(16);
    try {
      await FirebaseDatabase.instance
          .ref(
              'users/$phoneNumber/Infrastructure/${widget.areaName}/${widget.roomName}/Device')
          .child(randomString)
          .set({
        'electronicType': deviceType,
        'isFavorite': 0,
        'isOn': 0,
        'roomName': widget.roomName,
        'value': '0',
      });

      if (mounted) {
        Navigator.pop(context, 'true');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding device: $e')),
      );
    }
  }

  String getRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(Random().nextInt(chars.length)),
      ),
    );
  }
}

class DeviceCategory {
  final String name;
  final List<Device> devices;

  DeviceCategory({required this.name, required this.devices});
}

class Device {
  final String name;
  final String iconPath;

  Device(this.name, this.iconPath);
}

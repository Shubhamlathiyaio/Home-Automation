import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_home/devices/Fan/fan_page.dart';
import 'package:smart_home/devices/RGB/rgb_page.dart';
import 'package:smart_home/main.dart';
import 'package:smart_home/model/device_model.dart';
import 'package:smart_home/model/firebase_model.dart';
import 'package:smart_home/screens/add_devices.dart';
import 'package:smart_home/screens/scheduled_page.dart';

class ShowDevice extends StatefulWidget {
  final String roomName;
  final String areaName;
  final String roomImage;

  const ShowDevice({
    super.key,
    required this.roomName,
    required this.areaName,
    required this.roomImage,
  });

  @override
  State<ShowDevice> createState() => _ShowDeviceState();
}

class _ShowDeviceState extends State<ShowDevice> {
  FirebaseModel fire = FirebaseModel();
  bool isLoading = false;
  List<DeviceModel> devices = [];
  Timer? _scheduleTimer;
  final Map<String, String> roomImages = {
    'Bedroom': 'assets/rooms/bedroom.jpg',
    'Kitchen': 'assets/rooms/kitchen.jpg',
    'Living Room': 'assets/rooms/LivingRoom.jpg',
    'Bathroom': 'assets/rooms/bathrooms.jpg',
    'Dining Room': 'assets/rooms/dining.jpg',
    'Office': 'assets/rooms/office.jpg',
  };

  @override
  void initState() {
    super.initState();
    fetchData();

    // Add schedule checker for all devices
    _scheduleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        for (var device in devices) {
          fire.checkAndUpdateSchedule(
            widget.areaName,
            widget.roomName,
            device.id,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scheduleTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await fire.fetchDevicesFrom_Fb_OR_Map(
        databaseRef: FirebaseDatabase.instance
            .ref('users/$phoneNumber')
            .child('Infrastructure')
            .child(widget.areaName)
            .child(widget.roomName)
            .child('Device'),
      );

      if (mounted) {
        setState(() {
          devices = fire.devices;
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching devices: $e');
      }
      if (mounted) {
        setState(() {
          devices = [];
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
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF2D3436),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context, 'refresh'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.roomName,
                style: const TextStyle(color: Colors.white),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.roomImage.startsWith('http')
                      ? Image.network(
                          widget.roomImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/rooms/bedroom.jpg',
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          widget.roomImage,
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

          // Devices Grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2D3436),
                      ),
                    ),
                  )
                : devices.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No devices added yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final device = devices[index];
                            return _buildDeviceCard(device);
                          },
                          childCount: devices.length,
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2D3436),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDevices(
                roomName: widget.roomName,
                areaName: widget.areaName,
              ),
            ),
          );
          if (result == 'true') {
            fire.devices = [];
            await fetchData();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void deleteDevice(String deviceId, int index) async {
    try {
      await FirebaseDatabase.instance
          .ref('users/$phoneNumber/Infrastructure')
          .child(widget.areaName)
          .child(widget.roomName)
          .child('Device')
          .child(deviceId)
          .remove();

      setState(() {
        devices.removeAt(index);
      });

      // Send refresh signal back to homepage
      if (mounted) {
        Navigator.pop(context, 'refresh');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting device: $e');
      }
    }
  }

  Widget _buildDeviceCard(DeviceModel device) {
    return Dismissible(
      key: Key(device.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Device'),
            content: Text(
                'Are you sure you want to delete ${device.electronicType}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => deleteDevice(device.id, devices.indexOf(device)),
      child: GestureDetector(
        onLongPress: () => _editDeviceName(device),
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
                height: 40,
                color: device.isOn ? Colors.white : const Color(0xFF2D3436),
              ),
              const SizedBox(height: 12),
              Text(
                device.electronicType,
                style: TextStyle(
                  color: device.isOn ? Colors.white : const Color(0xFF2D3436),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Switch.adaptive(
                    value: device.isOn,
                    onChanged: (value) {
                      setState(() {
                        device.isOn = value;
                        device.value = value ? '1' : '0';
                      });
                      _updateDeviceState(device);
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.green,
                  ),
                  IconButton(
                    icon: const Icon(Icons.schedule),
                    color: device.isOn ? Colors.white : const Color(0xFF2D3436),
                    onPressed: () async {
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
                              final index = devices
                                  .indexWhere((d) => d.id == result['id']);
                              if (index != -1) {
                                devices[index].isOn = result['isOn'];
                                devices[index].value = result['value'];
                                devices[index].isFavorite =
                                    result['isFavorite'];
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
                              final index = devices
                                  .indexWhere((d) => d.id == result['id']);
                              if (index != -1) {
                                devices[index].isOn = result['isOn'];
                                devices[index].value = result['value'];
                                devices[index].isFavorite =
                                    result['isFavorite'];
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
                                roomName: widget.roomName,
                                deviceId: device.id,
                                areaName: widget.areaName,
                              ),
                            ),
                          );
                          break;
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      device.isFavorite ? Icons.star : Icons.star_border,
                      color:
                          device.isOn ? Colors.white : const Color(0xFF2D3436),
                    ),
                    onPressed: () => _toggleFavorite(device),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateDeviceState(DeviceModel device) async {
    try {
      await FirebaseDatabase.instance
          .ref(
              'users/$phoneNumber/Infrastructure/${widget.areaName}/${widget.roomName}/Device/${device.id}')
          .update({
        'isOn': device.isOn ? 1 : 0,
        'value': device.value,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating device state: $e');
      }
    }
  }

  void _toggleFavorite(DeviceModel device) async {
    try {
      setState(() {
        device.isFavorite = !device.isFavorite;
      });

      // Update in Infrastructure path
      await FirebaseDatabase.instance
          .ref(
              'users/$phoneNumber/Infrastructure/${widget.areaName}/${widget.roomName}/Device/${device.id}')
          .update({
        'isFavorite': device.isFavorite ? 1 : 0,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating favorite: $e');
      }
    }
  }

  void _editDeviceName(DeviceModel device) async {
    final TextEditingController nameController =
        TextEditingController(text: device.electronicType);

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Edit Device Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Device Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      try {
        // Update in Firebase
        await FirebaseDatabase.instance
            .ref(
                'users/$phoneNumber/Infrastructure/${widget.areaName}/${widget.roomName}/Device/${device.id}')
            .update({
          'electronicType': newName,
        });

        // Update local state
        setState(() {
          device.electronicType = newName;
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error updating device name: $e');
        }
      }
    }
  }
}

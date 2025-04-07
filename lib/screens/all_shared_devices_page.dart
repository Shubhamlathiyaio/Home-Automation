import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_home/model/device_model.dart';
import 'package:smart_home/model/firebase_model.dart';
import '../widgets/bottom_nav_bar.dart';

class AllSharedDevicesPage extends StatefulWidget {
  final String phoneNumber;

  const AllSharedDevicesPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<AllSharedDevicesPage> createState() => _AllSharedDevicesPageState();
}

class _AllSharedDevicesPageState extends State<AllSharedDevicesPage> {
  bool isLoading = true;
  Map<String, Map<String, List<DeviceModel>>> sharedDevices = {};

  @override
  void initState() {
    super.initState();
    _loadSharedDevices();
  }

  Future<void> _loadSharedDevices() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('shared_devices/${widget.phoneNumber}')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        for (var share in data.entries) {
          final shareData = share.value as Map<dynamic, dynamic>;
          final sharedBy = shareData['sharedBy'] as String;

          if (shareData.containsKey('devices')) {
            final devices = shareData['devices'] as Map<dynamic, dynamic>;

            for (var area in devices.entries) {
              final areaName = area.key as String;
              final rooms = area.value as Map<dynamic, dynamic>;

              sharedDevices[areaName] ??= {};
              sharedDevices[areaName]![sharedBy] ??= [];

              for (var room in rooms.entries) {
                final roomName = room.key;
                if (room.value is List) {
                  final devicesList = room.value as List;
                  for (var device in devicesList) {
                    final deviceData = device as Map<dynamic, dynamic>;
                    final deviceId = deviceData['id'] as String;
                    final permissions =
                        Map<String, bool>.from(deviceData['permissions'] ?? {});

                    // Fetch current device state
                    final deviceSnapshot = await FirebaseDatabase.instance
                        .ref(
                            'users/$sharedBy/Infrastructure/$areaName/$roomName/Device/$deviceId')
                        .get();

                    if (deviceSnapshot.exists) {
                      final currentData =
                          deviceSnapshot.value as Map<dynamic, dynamic>;
                      final deviceModel = DeviceModel.fromMap(
                        deviceId,
                        {
                          ...Map<String, dynamic>.from(currentData),
                          'roomName': roomName,
                          'areaName': areaName,
                          'image':
                              getDeviceImage(currentData['electronicType']),
                          'permissions': permissions,
                        },
                      );
                      sharedDevices[areaName]![sharedBy]!.add(deviceModel);
                    }
                  }
                }
              }
            }
          }
        }

        if (mounted) {
          setState(() => isLoading = false);
        }
      } else {
        if (mounted) {
          setState(() {
            sharedDevices = {};
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading shared devices: $e');
      }
      if (mounted) {
        setState(() {
          sharedDevices = {};
          isLoading = false;
        });
      }
    }
  }

  void _updateDeviceState(
      String sharedBy, String area, String room, DeviceModel device) async {
    try {
      // Update in original owner's database
      await FirebaseDatabase.instance
          .ref('users/$sharedBy/Infrastructure/$area/$room/Device/${device.id}')
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

  Future<void> _removeSharedDevice(DeviceModel device, String sharedBy) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('shared_devices/${widget.phoneNumber}')
          .get();

      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;
        String? shareId;

        // Find the correct share ID
        for (var entry in userData.entries) {
          final shareData = entry.value as Map<dynamic, dynamic>;
          if (shareData['sharedBy'] == sharedBy) {
            shareId = entry.key;
            break;
          }
        }

        if (shareId != null) {
          // Get the devices list
          final devicesSnapshot = await FirebaseDatabase.instance
              .ref(
                  'shared_devices/${widget.phoneNumber}/$shareId/devices/${device.areaName}/${device.roomName}')
              .get();

          if (devicesSnapshot.exists) {
            final devicesList = devicesSnapshot.value as List;
            final updatedList =
                devicesList.where((d) => d['id'] != device.id).toList();

            if (updatedList.isEmpty) {
              // If no devices left in room, remove the room
              await FirebaseDatabase.instance
                  .ref(
                      'shared_devices/${widget.phoneNumber}/$shareId/devices/${device.areaName}/${device.roomName}')
                  .remove();
            } else {
              // Update with remaining devices
              await FirebaseDatabase.instance
                  .ref(
                      'shared_devices/${widget.phoneNumber}/$shareId/devices/${device.areaName}/${device.roomName}')
                  .set(updatedList);
            }

            // Update the UI
            setState(() {
              sharedDevices[device.areaName ?? '']?[sharedBy]
                  ?.removeWhere((d) => d.id == device.id);

              // Clean up empty structures
              if (sharedDevices[device.areaName ?? '']?[sharedBy]?.isEmpty ??
                  false) {
                sharedDevices[device.areaName ?? '']?.remove(sharedBy);
                if (sharedDevices[device.areaName ?? '']?.isEmpty ?? false) {
                  sharedDevices.remove(device.areaName ?? '');
                }
              }
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Device removed from shared devices'),
                  backgroundColor: Color(0xFF2D3436),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing shared device: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF2D3436),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Shared With Me',
                style: TextStyle(
                  color: Colors.white,
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
                        ],
                      ),
                    ),
                  ),
                  // Add a subtle pattern overlay
                  CustomPaint(
                    painter: CirclePatternPainter(),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          sharedDevices.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/Lottie/empty.json',
                          height: 200,
                        ),
                        const Text(
                          'No shared devices found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Devices shared with you will appear here',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, locationIndex) {
                        final location =
                            sharedDevices.keys.elementAt(locationIndex);
                        final usersInLocation = sharedDevices[location]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Location Header
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Color(0xFF2D3436),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    location,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3436),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Users and their devices
                            ...usersInLocation.entries.map((userEntry) {
                              final sharedBy = userEntry.key;
                              final devices = userEntry.value;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Shared by header
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2D3436)
                                            .withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            color: Color(0xFF2D3436),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Shared by: +$sharedBy',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF2D3436),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Devices Grid
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final crossAxisCount =
                                            constraints.maxWidth > 600 ? 3 : 2;
                                        return GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            childAspectRatio: 0.85,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                          ),
                                          itemCount: devices.length,
                                          itemBuilder: (context, deviceIndex) {
                                            final device = devices[deviceIndex];
                                            return _buildDeviceCard(
                                                device, sharedBy);
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                      childCount: sharedDevices.length,
                    ),
                  ),
                ),
        ],
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: 2,
        phoneNumber: widget.phoneNumber,
        areaName: '', // Shared devices page doesn't need area name
      ),
    );
  }

  Widget _buildDeviceCard(DeviceModel device, String sharedBy) {
    final canControl = device.permissions?['control'] ?? false;

    return Dismissible(
      key: Key('${device.id}-${device.roomName}'),
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
            title: const Text('Remove Shared Device'),
            content: Text(
                'Are you sure you want to remove ${device.electronicType} from ${device.roomName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _removeSharedDevice(device, sharedBy),
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
            // Device Icon with Background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: device.isOn
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFF2D3436).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                device.image,
                height: 32,
                color: device.isOn ? Colors.white : const Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 12),

            // Device Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                device.electronicType,
                style: TextStyle(
                  color: device.isOn ? Colors.white : const Color(0xFF2D3436),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Room Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                device.roomName,
                style: TextStyle(
                  color: device.isOn ? Colors.white70 : Colors.grey,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),

            // Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Power Switch
                Switch.adaptive(
                  value: device.isOn,
                  onChanged: canControl
                      ? (value) {
                          setState(() {
                            device.isOn = value;
                            device.value = value ? '1' : '0';
                          });
                          _updateDeviceState(
                            sharedBy,
                            device.areaName ?? '',
                            device.roomName,
                            device,
                          );
                        }
                      : null,
                  activeColor: Colors.white,
                  activeTrackColor: canControl ? Colors.green : Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Add CirclePatternPainter class for the app bar background
class CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final maxRadius = size.width * 0.8;
    final center = Offset(size.width * 0.8, size.height * 0.2);

    for (int i = 0; i < 5; i++) {
      final radius = maxRadius * (i + 1) / 5;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

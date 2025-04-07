import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_home/main.dart';

class MySharedDevicesPage extends StatefulWidget {
  const MySharedDevicesPage({super.key});

  @override
  State<MySharedDevicesPage> createState() => _MySharedDevicesPageState();
}

class _MySharedDevicesPageState extends State<MySharedDevicesPage> {
  bool isLoading = true;
  List<SharedInfo> sharedList = [];

  @override
  void initState() {
    super.initState();
    _loadSharedDevices();
  }

  Future<void> _loadSharedDevices() async {
    try {
      final snapshot =
          await FirebaseDatabase.instance.ref('shared_devices').get();

      if (snapshot.exists && snapshot.value != null) {
        final allData = snapshot.value as Map<dynamic, dynamic>;

        allData.forEach((userNumber, userData) {
          if (userData is Map) {
            userData.forEach((shareId, shareData) {
              if (shareData is Map && shareData['sharedBy'] == phoneNumber) {
                final devices = shareData['devices'] as Map<dynamic, dynamic>;
                devices.forEach((area, rooms) {
                  rooms.forEach((room, deviceList) {
                    if (deviceList is List) {
                      for (var device in deviceList) {
                        sharedList.add(SharedInfo(
                          sharedTo: userNumber.toString(),
                          area: area.toString(),
                          room: room.toString(),
                          deviceName: device['electronicType'].toString(),
                          permissions: Map<String, bool>.from(
                              device['permissions'] ?? {}),
                        ));
                      }
                    }
                  });
                });
              }
            });
          }
        });
      }

      setState(() => isLoading = false);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading shared devices: $e');
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _updatePermission(
      SharedInfo device, String permission, bool value) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('shared_devices/${device.sharedTo}')
          .get();

      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;
        final shareId = userData.keys.first;

        // Get the devices list
        final devicesSnapshot = await FirebaseDatabase.instance
            .ref(
                'shared_devices/${device.sharedTo}/$shareId/devices/${device.area}/${device.room}')
            .get();

        if (devicesSnapshot.exists) {
          final devicesList = devicesSnapshot.value as List;

          // Find the device index
          final deviceIndex = devicesList
              .indexWhere((d) => d['electronicType'] == device.deviceName);

          if (deviceIndex != -1) {
            // Update the permission
            await FirebaseDatabase.instance
                .ref(
                    'shared_devices/${device.sharedTo}/$shareId/devices/${device.area}/${device.room}/$deviceIndex/permissions')
                .update({permission: value});

            setState(() {
              device.permissions[permission] = value;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permission updated')),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating permission: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating permission: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shared Devices'),
        backgroundColor: const Color(0xFF2D3436),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : sharedList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/Lottie/empty.json',
                        height: 200,
                      ),
                      const Text(
                        'No shared devices',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sharedList.length,
                  itemBuilder: (context, index) {
                    final item = sharedList[index];
                    return Dismissible(
                      key: Key('${item.sharedTo}-${item.deviceName}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Shared Device'),
                            content: Text(
                                'Are you sure you want to remove ${item.deviceName} shared with +${item.sharedTo}?'),
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
                      onDismissed: (_) => _removeSharedDevice(item),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: const Icon(Icons.devices),
                          title: Text(
                            item.deviceName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${item.area} > ${item.room}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: Container(
                            width: 80,
                            child: Text(
                              'Shared with\n+${item.sharedTo}',
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          children: [
                            SwitchListTile(
                              title: const Text(
                                'Control On/Off',
                                overflow: TextOverflow.ellipsis,
                              ),
                              value: item.permissions['control'] ?? false,
                              onChanged: (value) =>
                                  _updatePermission(item, 'control', value),
                            ),
                            SwitchListTile(
                              title: const Text(
                                'Schedule Device',
                                overflow: TextOverflow.ellipsis,
                              ),
                              value: item.permissions['schedule'] ?? false,
                              onChanged: (value) =>
                                  _updatePermission(item, 'schedule', value),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _removeSharedDevice(SharedInfo device) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('shared_devices/${device.sharedTo}')
          .get();

      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;
        final shareId = userData.keys.first;

        // Remove the specific device
        await FirebaseDatabase.instance
            .ref(
                'shared_devices/${device.sharedTo}/$shareId/devices/${device.area}/${device.room}')
            .get()
            .then((devicesSnapshot) async {
          if (devicesSnapshot.exists) {
            final devicesList = devicesSnapshot.value as List;
            final updatedList = devicesList
                .where((d) => d['electronicType'] != device.deviceName)
                .toList();

            if (updatedList.isEmpty) {
              // If no devices left in room, remove the room
              await FirebaseDatabase.instance
                  .ref(
                      'shared_devices/${device.sharedTo}/$shareId/devices/${device.area}/${device.room}')
                  .remove();
            } else {
              // Update with remaining devices
              await FirebaseDatabase.instance
                  .ref(
                      'shared_devices/${device.sharedTo}/$shareId/devices/${device.area}/${device.room}')
                  .set(updatedList);
            }
          }
        });

        setState(() {
          sharedList.removeWhere((item) =>
              item.sharedTo == device.sharedTo &&
              item.deviceName == device.deviceName);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device sharing removed')),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing shared device: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing device: $e')),
        );
      }
    }
  }
}

class SharedInfo {
  final String sharedTo;
  final String area;
  final String room;
  final String deviceName;
  final Map<String, bool> permissions;

  SharedInfo({
    required this.sharedTo,
    required this.area,
    required this.room,
    required this.deviceName,
    required this.permissions,
  });
}

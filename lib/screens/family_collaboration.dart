import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_home/main.dart';
import 'package:smart_home/model/device_model.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_home/screens/qr_scanner_page.dart';

class FamilyCollaboration extends StatefulWidget {
  const FamilyCollaboration({super.key, required String phoneNumber});

  @override
  State<FamilyCollaboration> createState() => _FamilyCollaborationState();
}

class _FamilyCollaborationState extends State<FamilyCollaboration> {
  bool _isLoading = true;
  Map<String, Map<String, List<DeviceModel>>> _selectedDevices = {};
  Map<String, Map<String, List<DeviceModel>>> _availableDevices = {};

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$phoneNumber/Infrastructure')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        for (var area in data.entries) {
          final areaName = area.key as String;
          final rooms = area.value as Map<dynamic, dynamic>;

          _availableDevices[areaName] = {};

          for (var room in rooms.entries) {
            final roomName = room.key as String;
            if (room.value is Map && room.value['Device'] is Map) {
              final devices = room.value['Device'] as Map<dynamic, dynamic>;

              _availableDevices[areaName]![roomName] =
                  devices.entries.map((device) {
                final deviceData = Map<String, dynamic>.from(device.value);
                deviceData['id'] = device.key;
                deviceData['roomName'] = roomName;
                return DeviceModel.fromMap(device.key, deviceData);
              }).toList();
            }
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading devices: $e');
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleDeviceSelection(String area, String room, DeviceModel device) {
    setState(() {
      _selectedDevices[area] ??= {};
      _selectedDevices[area]![room] ??= [];

      final devices = _selectedDevices[area]![room]!;
      final index = devices.indexWhere((d) => d.id == device.id);

      if (index >= 0) {
        devices.removeAt(index);
        if (devices.isEmpty) {
          _selectedDevices[area]!.remove(room);
          if (_selectedDevices[area]!.isEmpty) {
            _selectedDevices.remove(area);
          }
        }
      } else {
        devices.add(device);
      }
    });
  }

  void _showPermissionsDialog(Function(Map<String, bool>) onSelect) {
    Map<String, bool> permissions = {
      'control': true,
      'schedule': false,
      'delete': false,
    };

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Set Permissions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 20),
              ...permissions.entries
                  .map((e) => SwitchListTile(
                        title: Text(e.key.capitalize()),
                        value: e.value,
                        onChanged: (value) {
                          permissions[e.key] = value;
                          if (mounted) setState(() {});
                        },
                      ))
                  .toList(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3436),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onSelect(permissions);
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQRCode() {
    if (_selectedDevices.isEmpty) return;

    final sharedData = {
      'sharedBy': phoneNumber,
      'devices': _selectedDevices.map((area, rooms) {
        return MapEntry(area, rooms.map((room, devices) {
          return MapEntry(
            room,
            devices
                .map((device) => {
                      'id': device.id,
                      'electronicType': device.electronicType,
                      'roomName': device.roomName,
                      'permissions': {
                        'control': true, // Default permissions
                        'schedule': false,
                      },
                    })
                .toList(),
          );
        }));
      }),
    };

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share QR Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              QrImageView(
                data: jsonEncode(sharedData),
                size: 200,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D3436),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _countSelectedDevices() {
    int count = 0;
    for (var area in _selectedDevices.values) {
      for (var room in area.values) {
        count += room.length;
      }
    }
    return count;
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      itemCount: _availableDevices.length,
      itemBuilder: (context, areaIndex) {
        final area = _availableDevices.keys.elementAt(areaIndex);
        final rooms = _availableDevices[area]!;

        return ExpansionTile(
          title: Text(
            area,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          children: rooms.entries.map((room) {
            return ExpansionTile(
              title: Text(
                room.key,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D3436),
                ),
              ),
              leading: Icon(
                Icons.room_preferences,
                color: Theme.of(context).primaryColor,
              ),
              children: room.value.map((device) {
                final isSelected = _selectedDevices[area]?[room.key]
                        ?.any((d) => d.id == device.id) ??
                    false;

                return CheckboxListTile(
                  title: Text(device.electronicType),
                  subtitle: Text(device.roomName),
                  value: isSelected,
                  onChanged: (value) {
                    _toggleDeviceSelection(area, room.key, device);
                  },
                  secondary: SvgPicture.asset(
                    device.image,
                    height: 24,
                    color: const Color(0xFF2D3436),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _processQRCode(String rawValue) async {
    try {
      final data = jsonDecode(rawValue);
      final sharedBy = data['sharedBy'];

      // Get existing shared devices
      final snapshot = await FirebaseDatabase.instance
          .ref('shared_devices/$phoneNumber')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final existingData = snapshot.value as Map<dynamic, dynamic>;
        String? existingKey;
        bool shouldCreateNewPath = true;

        // Check if same path exists
        for (var entry in existingData.entries) {
          final shareData = entry.value as Map<dynamic, dynamic>;
          if (shareData['sharedBy'] == sharedBy &&
              shareData.containsKey('devices')) {
            existingKey = entry.key;
            shouldCreateNewPath = false;
            break;
          }
        }

        if (!shouldCreateNewPath && existingKey != null) {
          // Update existing path
          await FirebaseDatabase.instance
              .ref('shared_devices/$phoneNumber/$existingKey')
              .update(data);
        } else {
          // Create new path
          await FirebaseDatabase.instance
              .ref('shared_devices/$phoneNumber')
              .push()
              .set(data);
        }
      } else {
        // First time sharing
        await FirebaseDatabase.instance
            .ref('shared_devices/$phoneNumber')
            .push()
            .set(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access granted successfully'),
            backgroundColor: Color(0xFF2D3436),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Devices'),
        backgroundColor: const Color(0xFF2D3436),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QRScannerPage(),
                ),
              );

              if (result != null) {
                _processQRCode(result);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableDevices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/Lottie/empty.json',
                        height: 200,
                      ),
                      const Text(
                        'No devices to share',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D3436),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                        ),
                        label: const Text('Scan QR Code'),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QRScannerPage(),
                            ),
                          );

                          if (result != null) {
                            _processQRCode(result);
                          }
                        },
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Lottie.asset('assets/Lottie/qr.json'),
                    ),
                    Expanded(child: _buildDeviceList()),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D3436),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.qr_code),
                        label: Text(
                          _selectedDevices.isEmpty
                              ? 'Select Devices to Share'
                              : 'Generate QR Code (${_countSelectedDevices()} selected)',
                        ),
                        onPressed:
                            _selectedDevices.isEmpty ? null : _showQRCode,
                      ),
                    ),
                  ],
                ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

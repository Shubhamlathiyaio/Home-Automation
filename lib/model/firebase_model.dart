// ignore_for_file: non_constant_identifier_names

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:smart_home/main.dart';
import 'package:smart_home/model/device_model.dart';

class FirebaseModel {
  bool isLoading = false;
  List<DeviceModel> devices = [];

  getFBDataInMap(DatabaseReference databaseRef) async {
    isLoading = true;
    Map<dynamic, dynamic> devicesData = {};
    try {
      DatabaseEvent event = await databaseRef.once();
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null && snapshot.value is Map) {
        devicesData = snapshot.value as Map<dynamic, dynamic>;
        isLoading = false;
      } else {
        if (kDebugMode) {
          print('No valid device data found.');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print("Error fetching devices: $error");
      }
    } finally {
      isLoading = false;
    }
    return devicesData;
  }

  fetchDevicesFrom_Fb_OR_Map(
      {DatabaseReference? databaseRef, Map<dynamic, dynamic>? map}) async {
    isLoading = true;
    devices.clear();

    try {
      Map<dynamic, dynamic> devicesData =
          map ?? await getFBDataInMap(databaseRef!);

      if (devicesData.isNotEmpty) {
        devicesData.forEach((deviceId, deviceData) {
          if (deviceData is Map) {
            try {
              Map<String, dynamic> safeMap = {
                'electronicType': deviceData['electronicType'],
                'isOn': deviceData['isOn'] ?? 0,
                'value': deviceData['value']?.toString() ?? '0',
                'isFavorite': deviceData['isFavorite'] ?? 0,
                'roomName': deviceData['roomName'] ?? '',
              };

              safeMap['image'] =
                  getDeviceImage(safeMap['electronicType'] ?? '');

              devices.add(DeviceModel.fromMap(deviceId.toString(), safeMap));
            } catch (e) {
              if (kDebugMode) {
                print('Error processing device $deviceId: $e');
              }
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchDevicesFrom_Fb_OR_Map: $e');
      }
    } finally {
      isLoading = false;
    }
  }

  //Update
  update(DeviceModel model) async {
    DatabaseReference deviceRef = FirebaseDatabase.instance
        .ref('users/$phoneNumber/Infrastructure')
        .child('Home')
        .child(model.roomName)
        .child('Device')
        .child(model.id);

    await deviceRef.update(model.toMap()).then((value) {
      if (kDebugMode) {
        print("Device updated successfully");
      }
    }).catchError((error) {
      if (kDebugMode) {
        print("Failed to update device: $error");
      }
    });

    await fetchDevicesFrom_Fb_OR_Map(
        databaseRef: FirebaseDatabase.instance
            .ref('users/$phoneNumber')
            .child('Infrastructure')
            .child('Home')
            .child(model.roomName)
            .child('Device'));
    return devices;
  }

  //bool update
  boolUpdateFav(DeviceModel model, String roomName) async {
    await FirebaseDatabase.instance
        .ref('users/$phoneNumber/Infrastructure')
        .child(roomName)
        .child(model.roomName)
        .child('Device')
        .child(model.id)
        .update({'isFavorite': model.isFavorite ? 1 : 0});
  }

  boolUpdateOn(DeviceModel model, String roomName, String areaName) async {
    await FirebaseDatabase.instance
        .ref('users/$phoneNumber/Infrastructure')
        .child(areaName)
        .child(model.roomName)
        .child('Device')
        .child(model.id)
        .update({
      'isOn': model.isOn ? 1 : 0,
      'value': model.value,
    });
  }

  updateTime(DeviceModel model, String roomName, String areaName) async {
    DatabaseReference deviceRef = FirebaseDatabase.instance
        .ref('users/$phoneNumber/Infrastructure')
        .child(areaName)
        .child(roomName)
        .child('Device')
        .child(model.id)
        .child('device_setting');

    await deviceRef.update({
      'update_time':
          DateFormat('dd MMMM yyyy hh:mm:ss a').format(DateTime.now()),
      'sync_time': '',
      'mode': 'manual',
    });
  }

  //value update
  valueUpdate(DeviceModel model, String areaName) async {
    await FirebaseDatabase.instance
        .ref('users/$phoneNumber/Infrastructure')
        .child(areaName)
        .child(model.roomName)
        .child('Device')
        .child(model.id)
        .update({'value': model.value});
  }

  Future<void> checkAndUpdateSchedule(
      String areaName, String roomName, String deviceId) async {
    try {
      final deviceRef = FirebaseDatabase.instance.ref(
          'users/$phoneNumber/Infrastructure/$areaName/$roomName/Device/$deviceId');

      final snapshot = await deviceRef.get();
      if (!snapshot.exists) return;

      final deviceData = snapshot.value as Map<dynamic, dynamic>;
      if (!deviceData.containsKey('schedule')) return;

      final schedule = deviceData['schedule'] as Map<dynamic, dynamic>;
      if (!(schedule['isEnabled'] ?? false)) return;

      final now = DateTime.now();

      // Check if today is in scheduled days
      final weekDay = DateFormat('E').format(now).substring(0, 3);
      final days = List<String>.from(schedule['days'] ?? []);
      if (!days.contains(weekDay)) return;

      // Parse schedule times with exact seconds
      final startTimeParts = (schedule['startTime'] as String).split(':');
      final endTimeParts = (schedule['endTime'] as String).split(':');

      final startTimeMinutes =
          int.parse(startTimeParts[0]) * 60 + int.parse(startTimeParts[1]);
      final endTimeMinutes =
          int.parse(endTimeParts[0]) * 60 + int.parse(endTimeParts[1]);
      final currentMinutes = now.hour * 60 + now.minute;

      // Determine if device should be on or off
      bool shouldBeOn;
      if (endTimeMinutes > startTimeMinutes) {
        // Same day schedule
        shouldBeOn = currentMinutes >= startTimeMinutes &&
            currentMinutes < endTimeMinutes;
      } else {
        // Overnight schedule
        shouldBeOn = currentMinutes >= startTimeMinutes ||
            currentMinutes < endTimeMinutes;
      }

      // Get current state
      final currentIsOn = (deviceData['isOn'] ?? 0) == 1;

      // Only update if state needs to change
      if (currentIsOn != shouldBeOn) {
        await deviceRef.update({
          'isOn': shouldBeOn ? 1 : 0,
          'value': shouldBeOn ? '1' : '0',
          'device_setting': {
            'update_time': DateFormat('dd MMMM yyyy hh:mm:ss a').format(now),
            'mode': 'schedule'
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking schedule: $e');
      }
    }
  }
}

addImage(Map map) {
  try {
    Map<String, dynamic> fullMap = Map<String, dynamic>.from(map);
    fullMap['image'] = getDeviceImage(map['electronicType'] ?? '');
    return fullMap;
  } catch (e) {
    if (kDebugMode) {
      print('Error in addImage: $e');
    }
    return map;
  }
}

String getDeviceImage(String deviceType) {
  switch (deviceType) {
    case 'T.V.':
      return 'assets/appliances/tv.svg';
    case 'Refrigerator':
      return 'assets/appliances/refrigerator.svg';
    case 'Microwave':
      return 'assets/appliances/microwave.svg';
    case 'Washing Machine':
      return 'assets/appliances/washing-machine.svg';
    case 'Air Conditioner':
      return 'assets/appliances/air-conditioner.svg';
    case 'Lamp':
      return 'assets/appliances/light.svg';
    case 'Fan':
      return 'assets/appliances/ceiling-fan.svg';
    case 'Ceiling Lamp':
      return 'assets/appliances/lamp.svg';
    case 'Bulb':
      return 'assets/appliances/bulb.svg';
    case 'CCTV Camera':
      return 'assets/appliances/cctv.svg';
    case 'Computer':
      return 'assets/appliances/computer.svg';
    case 'Cooler':
      return 'assets/appliances/cooler.svg';
    case 'Exhaust Fan':
      return 'assets/appliances/cpu.svg';
    case 'Desk Light':
      return 'assets/appliances/desk-light.svg';
    case 'Humidi Fire':
      return 'assets/appliances/humidity-fire.svg';
    case 'Plug':
      return 'assets/appliances/plug.svg';
    case 'Printer':
      return 'assets/appliances/printer.svg';
    case 'Projector':
      return 'assets/appliances/projector.svg';
    case 'RGB Light':
      return 'assets/appliances/rgb-light.svg';
    case 'Speaker':
      return 'assets/appliances/speaker.svg';
    case 'Table Fan':
      return 'assets/appliances/table-fan.svg';
    default:
      return 'assets/appliances/tv.svg';
  }
}

String getRoomImage(String roomName) {
  switch (roomName) {
    case 'Bathroom':
      return 'assets/rooms/bathrooms.jpg';
    case 'Bedroom':
      return 'assets/rooms/bedroom.jpg';
    case 'Kitchen':
      return 'assets/rooms/kitchen.jpg';
    case 'Living Room':
      return 'assets/rooms/LivingRoom.jpg';
    case 'Dining Room':
      return 'assets/rooms/dining.jpg';
    case 'Office':
      return 'assets/rooms/office.jpg';
    default:
      return 'assets/photos/default_room.jpg';
  }
}

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/main.dart';
import 'package:smart_home/model/device_model.dart';
import 'package:smart_home/model/firebase_model.dart';
import 'package:smart_home/model/weather_model/weather.dart';
import 'package:smart_home/screens/add_location.dart';
import 'package:smart_home/screens/favourites.dart';
import 'package:smart_home/screens/show_device.dart';
import 'package:smart_home/screens/all_shared_devices_page.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Homepage extends StatefulWidget {
  String number;

  Homepage({super.key, required this.number});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  FirebaseModel fire = FirebaseModel();
  bool isLoading = false;
  int ind = 0;
  final WeatherService weatherService = WeatherService();
  Weather _weather =
      Weather(description: 'No data', temperature: 0.0, icon: '');
  String date = '';
  String location = '';
  String _selectedLocation = '';
  String weatherLocation = '';
  String currentLocation = '';
  String areaName = '';
  String userName = '';
  List<Map<String, String>> rooms = [];
  bool isInitializing = true;
  List<Map<String, String>> _locationsList = [];
  String _selectedLocationId = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh rooms when returning to this screen
    if (!isInitializing) {
      _fetchRooms();
    }
  }

  Future<void> _initializeData() async {
    setState(() {
      isInitializing = true;
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLogin', true);
    try {
      await _getCurrentLocation();
      await _fetchUserName();
      await _fetchRooms();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing data: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isInitializing = false;
        });
      }
    }
  }

  String _formatLocation(String loc) {
    return loc.trim();
  }

  Future<void> locationData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final DatabaseReference locationRef =
          FirebaseDatabase.instance.ref('users/$phoneNumber').child('Location');

      DatabaseEvent event = await locationRef.once();
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> data = event.snapshot.value as Map;
        List<Map<String, String>> locationsList = [];
        String? matchingLocationId;

        data.forEach((key, value) {
          if (value is Map &&
              value.containsKey('location') &&
              value.containsKey('title')) {
            String retrievedLocation = _formatLocation(value['location']);
            String title = value['title'];
            locationsList.add({
              'id': key,
              'title': title,
              'location': retrievedLocation,
            });

            // Check if this location matches current location
            if (currentLocation.isNotEmpty &&
                retrievedLocation
                    .toLowerCase()
                    .contains(currentLocation.toLowerCase())) {
              matchingLocationId = key;
            }
          }
        });

        setState(() {
          _locationsList = locationsList;

          if (_locationsList.isNotEmpty) {
            if (matchingLocationId != null) {
              // If there's a matching location, put it first
              var matchingLocation = _locationsList
                  .firstWhere((loc) => loc['id'] == matchingLocationId);
              _locationsList.remove(matchingLocation);
              _locationsList.insert(0, matchingLocation);
              _selectedLocationId = matchingLocationId!;
            } else {
              // If no match, use the first location
              _selectedLocationId = _locationsList[0]['id']!;
            }

            var selectedLocation = _locationsList
                .firstWhere((loc) => loc['id'] == _selectedLocationId);
            _selectedLocation = selectedLocation['location']!;

            int commaIndex = _selectedLocation.indexOf(',');
            if (commaIndex != -1) {
              weatherLocation =
                  _selectedLocation.substring(commaIndex + 1).trim();
              areaName = _selectedLocation.substring(0, commaIndex).trim();
            } else {
              weatherLocation = _selectedLocation;
              areaName = _selectedLocation.trim();
            }
            _getWeather();
            _fetchRooms();
            fetchFavoriteDevices();
          }
        });
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching locations: $e');
      }
      setState(() {
        isLoading = false;
        _locationsList = [];
        _selectedLocationId = '';
        _selectedLocation = '';
        areaName = '';
      });
    }
  }

  List<DropdownMenuItem<String>> _getLocationItems() {
    return _locationsList.map((location) {
      return DropdownMenuItem<String>(
        value: location['id'],
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location['title']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location['location']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied';
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            currentLocation =
                '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
            weatherLocation =
                '${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
            location = currentLocation;
            date = DateFormat('dd MMMM yyyy').format(DateTime.now());
          });
        }

        // Fetch location data after getting current location
        await locationData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in reverse geocoding: $e');
      }
    }
  }

  void _getWeather() async {
    if (weatherLocation.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final data = await weatherService.fetchWeather(weatherLocation);
      if (mounted) {
        setState(() {
          _weather = Weather.fromJson(data);
          if (kDebugMode) {
            print('weather = ${_weather.temperature}');
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching weather: $e');
      }
    }
  }

  Future<void> fetchFavoriteDevices() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$phoneNumber/Infrastructure/$areaName')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final roomsData = snapshot.value as Map<dynamic, dynamic>;
        List<DeviceModel> favoriteDevices = [];

        for (var roomData in roomsData.entries) {
          final roomName = roomData.key.toString();
          final roomValue = roomData.value;

          if (roomValue is Map && roomValue['Device'] is Map) {
            final devicesData = roomValue['Device'] as Map<dynamic, dynamic>;

            devicesData.forEach((deviceId, deviceData) {
              if (deviceData is Map && deviceData['isFavorite'] == 1) {
                try {
                  Map<String, dynamic> deviceMap = {
                    'electronicType': deviceData['electronicType'],
                    'isOn': deviceData['isOn'] ?? 0,
                    'value': deviceData['value']?.toString() ?? '0',
                    'isFavorite': deviceData['isFavorite'] ?? 0,
                    'roomName': roomName,
                  };
                  deviceMap['image'] =
                      getDeviceImage(deviceMap['electronicType'] ?? '');
                  favoriteDevices
                      .add(DeviceModel.fromMap(deviceId.toString(), deviceMap));
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
            // Update your homepage's devices list
            devices = favoriteDevices;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching favorite devices: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF2D3436),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Loading your smart home...',
                    style: TextStyle(
                      color: Color(0xFF2D3436),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 80,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  title: Text(
                    userName,
                    style: const TextStyle(
                      color: Color(0xFF2D3436),
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.star_border_rounded,
                        color: Color(0xFF2D3436),
                      ),
                      onPressed: () async {
                        String? callBack = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FavouritePage(
                              areaName: areaName,
                              phoneNumber: widget.number,
                            ),
                          ),
                        );
                        if ((callBack == null || callBack.isNotEmpty) &&
                            callBack == 'true') {
                          fire.devices = [];
                          fetchFavoriteDevices();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Color(0xFF2D3436),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllSharedDevicesPage(
                              phoneNumber: widget.number,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: ButtonTheme(
                        alignedDropdown: true,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLocationId.isEmpty
                                ? null
                                : _selectedLocationId,
                            hint: const Text('Select Location'),
                            icon: const Icon(Icons.keyboard_arrow_down),
                            isExpanded: true,
                            itemHeight: null,
                            items: _getLocationItems(),
                            onChanged: (String? newValue) {
                              if (newValue == 'add_new_location') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddLocation(number: phoneNumber),
                                  ),
                                ).then((value) {
                                  if (value == true) {
                                    locationData();
                                  }
                                });
                              } else if (newValue != null) {
                                var selectedLocation = _locationsList
                                    .firstWhere((loc) => loc['id'] == newValue);

                                setState(() {
                                  _selectedLocationId = newValue;
                                  _selectedLocation =
                                      selectedLocation['location']!;

                                  int commaIndex =
                                      _selectedLocation.indexOf(',');
                                  if (commaIndex != -1) {
                                    weatherLocation = _selectedLocation
                                        .substring(commaIndex + 1)
                                        .trim();
                                    areaName = _selectedLocation
                                        .substring(0, commaIndex)
                                        .trim();
                                  } else {
                                    weatherLocation = _selectedLocation;
                                    areaName = _selectedLocation.trim();
                                  }
                                  fire.devices = [];
                                  rooms =
                                      []; // Clear rooms when changing location
                                });
                                _getWeather();
                                _fetchRooms();
                                fetchFavoriteDevices();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Weather card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_weather.temperature.toString().substring(0, _weather.temperature.toString().length >= 2 ? 2 : 1)}°C',
                                  style: const TextStyle(
                                    color: Color(0xFF2D3436),
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _weather.description,
                                  style: const TextStyle(
                                    color: Color(0xFF2D3436),
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Image.network(
                            _weather.icon.isNotEmpty
                                ? 'https://openweathermap.org/img/wn/${_weather.icon}@2x.png'
                                : 'https://openweathermap.org/img/wn/02d@2x.png',
                            height: 100,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.cloud,
                                color: Color(0xFF2D3436),
                                size: 80,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Rooms Grid
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rooms',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: isLoading
                      ? const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2D3436),
                            ),
                          ),
                        )
                      : rooms.isEmpty
                          ? const SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  'No rooms added yet',
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
                                childAspectRatio: 1.2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final room = rooms[index];
                                  return Dismissible(
                                    key: Key('$areaName-${room['name']}'),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade400,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 16),
                                      child: const Icon(Icons.delete,
                                          color: Colors.white),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Room'),
                                          content: Text(
                                              'Are you sure you want to delete ${room['name']}?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    onDismissed: (_) =>
                                        _deleteRoom(areaName, room['name']!),
                                    child: GestureDetector(
                                      onTap: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ShowDevice(
                                              roomName: room['name']!,
                                              areaName: areaName,
                                              roomImage: room['image']!,
                                            ),
                                          ),
                                        );
                                        if (result == 'refresh') {
                                          await _fetchRooms();
                                          await updateDeviceCounts();
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              Image(
                                                image: room['image']!
                                                        .startsWith('http')
                                                    ? NetworkImage(
                                                        room['image']!)
                                                    : AssetImage(room['image']!)
                                                        as ImageProvider,
                                                fit: BoxFit.cover,
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 12,
                                                left: 12,
                                                right: 12,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      room['name']!,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        shadows: [
                                                          Shadow(
                                                            offset:
                                                                const Offset(
                                                                    0, 1),
                                                            blurRadius: 4,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.5),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.3),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                              Icons.device_hub,
                                                              color:
                                                                  Colors.white,
                                                              size: 14),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            '${room['deviceCount'] ?? '0'} Devices',
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                childCount: rooms.length,
                              ),
                            ),
                ),

                // Rest of the content...
              ],
            ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: 0,
        phoneNumber: widget.number,
        areaName: areaName,
      ),
    );
  }

  Future<void> _fetchUserName() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$phoneNumber')
          .child('Profile')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        if (mounted) {
          setState(() {
            userName = data['userName'] ?? '';
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching username: $e');
      }
    }
  }

  Future<void> _fetchRooms() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      if (areaName.isEmpty) {
        setState(() {
          rooms = [];
          isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseDatabase.instance
          .ref('users/$phoneNumber/Infrastructure/$areaName')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, String>> newRooms = [];

        data.forEach((key, value) {
          if (value is Map) {
            String roomName = key.toString();
            String imagePath;
            bool isCustom = value['isCustom'] == true;

            // Handle image path based on room type
            if (isCustom && value['image'] != null) {
              // For custom rooms, use the stored image URL
              imagePath = value['image'].toString();
            } else {
              // For default rooms, use asset path
              imagePath = value['image'] != null
                  ? value['image'].toString()
                  : getRoomDefaultImage(roomName);
            }

            // Count devices in this room
            int deviceCount = 0;
            if (value['Device'] is Map) {
              deviceCount = (value['Device'] as Map).length;
            }

            newRooms.add({
              'name': roomName,
              'image': imagePath,
              'deviceCount': deviceCount.toString(),
              'isCustom': isCustom.toString(),
            });
          }
        });

        // Sort rooms alphabetically
        newRooms.sort((a, b) => a['name']!.compareTo(b['name']!));

        if (mounted) {
          setState(() {
            rooms = newRooms;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            rooms = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching rooms: $e');
      }
      if (mounted) {
        setState(() {
          rooms = [];
          isLoading = false;
        });
      }
    }
  }

  String getRoomDefaultImage(String roomName) {
    roomName = roomName.toLowerCase();
    if (roomName.contains('bedroom')) return 'assets/rooms/bedroom.jpg';
    if (roomName.contains('living')) return 'assets/rooms/LivingRoom.jpg';
    if (roomName.contains('kitchen')) return 'assets/rooms/kitchen.jpg';
    if (roomName.contains('bathroom')) return 'assets/rooms/bathrooms.jpg';
    if (roomName.contains('dining')) return 'assets/rooms/dining.jpg';
    if (roomName.contains('office')) return 'assets/rooms/office.jpg';
    return 'assets/rooms/bedroom.jpg';
  }

  Future<void> updateDeviceCounts() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$phoneNumber/Infrastructure/$areaName')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, String>> updatedRooms = [];

        for (var room in rooms) {
          String roomName = room['name']!;
          if (data[roomName] != null && data[roomName]['Device'] is Map) {
            int deviceCount = (data[roomName]['Device'] as Map).length;
            updatedRooms.add({
              ...room,
              'deviceCount': deviceCount.toString(),
            });
          } else {
            updatedRooms.add({
              ...room,
              'deviceCount': '0',
            });
          }
        }

        if (mounted) {
          setState(() {
            rooms = updatedRooms;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating device counts: $e');
      }
    }
  }

  Future<void> _deleteRoom(String areaName, String roomName) async {
    try {
      // First get the room data to check if it's a custom room and get the image URL
      final roomSnapshot = await FirebaseDatabase.instance
          .ref('users/$phoneNumber/Infrastructure/$areaName/$roomName')
          .get();

      if (roomSnapshot.exists && roomSnapshot.value != null) {
        final roomData = roomSnapshot.value as Map<dynamic, dynamic>;
        final bool isCustomRoom = roomData['isCustom'] == true;
        final String? imageUrl = roomData['image']?.toString();

        // If it's a custom room and has an image URL, delete from Storage
        if (isCustomRoom && imageUrl != null && imageUrl.startsWith('http')) {
          try {
            // Get reference from URL and delete
            final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
            await storageRef.delete();
            if (kDebugMode) {
              print('Custom room image deleted successfully');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error deleting room image: $e');
            }
          }
        }
      }

      // Delete from Infrastructure path
      await FirebaseDatabase.instance
          .ref('users/$phoneNumber/Infrastructure/$areaName/$roomName')
          .remove();

      // Delete shared devices in this room
      final sharedSnapshot =
          await FirebaseDatabase.instance.ref('shared_devices').get();

      if (sharedSnapshot.exists && sharedSnapshot.value != null) {
        final allShared = sharedSnapshot.value as Map<dynamic, dynamic>;

        for (var userShares in allShared.entries) {
          final userData = userShares.value as Map<dynamic, dynamic>;

          for (var share in userData.entries) {
            if (share.value is Map &&
                share.value['sharedBy'] == phoneNumber &&
                share.value['devices'] is Map) {
              final devices = share.value['devices'] as Map<dynamic, dynamic>;

              if (devices.containsKey(areaName)) {
                final rooms = devices[areaName] as Map<dynamic, dynamic>;
                if (rooms.containsKey(roomName)) {
                  await FirebaseDatabase.instance
                      .ref(
                          'shared_devices/${userShares.key}/${share.key}/devices/$areaName/$roomName')
                      .remove();
                }
              }
            }
          }
        }
      }

      // Update the rooms list in state
      setState(() {
        rooms.removeWhere((room) => room['name'] == roomName);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$roomName deleted successfully')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting room: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting room: $e')),
        );
      }
    }
  }
}

class DeviceModel {
  String id;
  String image;
  String electronicType;
  bool isOn;
  String value;
  bool isFavorite;
  String roomName;
  String? areaName;
  Map<String, bool>? permissions;

  DeviceModel({
    required this.id,
    required this.image,
    required this.electronicType,
    required this.isOn,
    required this.value,
    required this.isFavorite,
    required this.roomName,
    this.areaName,
    this.permissions,
  });

  factory DeviceModel.fromMap(String id, Map<String, dynamic> map) {
    return DeviceModel(
      id: id,
      image: map['image'] ?? '',
      electronicType: map['electronicType'] ?? '',
      isOn: map['isOn'] == 1,
      value: map['value']?.toString() ?? '0',
      isFavorite: map['isFavorite'] == 1,
      roomName: map['roomName'] ?? '',
      areaName: map['areaName'],
      permissions: map['permissions'] != null
          ? Map<String, bool>.from(map['permissions'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'electronicType': electronicType,
      'isOn': isOn ? 1 : 0,
      //'image': image,
      'value': value,
      'isFavorite': isFavorite ? 1 : 0,
      'roomName': roomName,
    };
  }

  @override
  String toString() {
    return 'DeviceModel{id: $id, image: $image, electronicType: $electronicType, isOn: $isOn, value: $value, isFavorite: $isFavorite, roomName: $roomName}';
  }
}

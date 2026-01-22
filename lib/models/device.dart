import 'package:flutter/material.dart';

enum DeviceType {
  light,
  fan,
  waterPump,
  gasSensor,
  sensorOnly,
  custom,
}

extension DeviceTypeExtension on DeviceType {
  String get displayName {
    switch (this) {
      case DeviceType.light:
        return 'Light';
      case DeviceType.fan:
        return 'Fan';
      case DeviceType.waterPump:
        return 'Water Pump';
      case DeviceType.gasSensor:
        return 'Gas Sensor';
      case DeviceType.sensorOnly:
        return 'Sensor Only';
      case DeviceType.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case DeviceType.light:
        return Icons.lightbulb_outline;
      case DeviceType.fan:
        return Icons.air;
      case DeviceType.waterPump:
        return Icons.water_drop_outlined;
      case DeviceType.gasSensor:
        return Icons.sensors;
      case DeviceType.sensorOnly:
        return Icons.speed;
      case DeviceType.custom:
        return Icons.settings_input_component;
    }
  }

  Color get color {
    switch (this) {
      case DeviceType.light:
        return const Color(0xFFFFEB3B);
      case DeviceType.fan:
        return const Color(0xFF00BCD4);
      case DeviceType.waterPump:
        return const Color(0xFF2196F3);
      case DeviceType.gasSensor:
        return const Color(0xFFFF9800);
      case DeviceType.sensorOnly:
        return const Color(0xFF9C27B0);
      case DeviceType.custom:
        return const Color(0xFF607D8B);
    }
  }
}

class Device {
  final String id;
  String name;
  DeviceType type;
  String ipAddress;
  int? gpioPin;
  String? roomId;
  bool isOn;
  bool isOnline;
  int? batteryLevel;
  bool hasBattery;
  int brightness; // 0-100 for lights
  int fanSpeed; // 1-5 for fans
  int waterLevel; // 0-100 for pumps
  double lpgValue; // For gas sensors
  double coValue; // For gas sensors
  bool notificationsEnabled;
  DateTime lastSeen;
  DateTime createdAt;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.ipAddress,
    this.gpioPin,
    this.roomId,
    this.isOn = false,
    this.isOnline = false,
    this.batteryLevel,
    this.hasBattery = false,
    this.brightness = 100,
    this.fanSpeed = 1,
    this.waterLevel = 50,
    this.lpgValue = 0,
    this.coValue = 0,
    this.notificationsEnabled = true,
    DateTime? lastSeen,
    DateTime? createdAt,
  })  : lastSeen = lastSeen ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Device copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? ipAddress,
    int? gpioPin,
    String? roomId,
    bool? isOn,
    bool? isOnline,
    int? batteryLevel,
    bool? hasBattery,
    int? brightness,
    int? fanSpeed,
    int? waterLevel,
    double? lpgValue,
    double? coValue,
    bool? notificationsEnabled,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ipAddress: ipAddress ?? this.ipAddress,
      gpioPin: gpioPin ?? this.gpioPin,
      roomId: roomId ?? this.roomId,
      isOn: isOn ?? this.isOn,
      isOnline: isOnline ?? this.isOnline,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      hasBattery: hasBattery ?? this.hasBattery,
      brightness: brightness ?? this.brightness,
      fanSpeed: fanSpeed ?? this.fanSpeed,
      waterLevel: waterLevel ?? this.waterLevel,
      lpgValue: lpgValue ?? this.lpgValue,
      coValue: coValue ?? this.coValue,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'ipAddress': ipAddress,
        'gpioPin': gpioPin,
        'roomId': roomId,
        'isOn': isOn,
        'isOnline': isOnline,
        'batteryLevel': batteryLevel,
        'hasBattery': hasBattery,
        'brightness': brightness,
        'fanSpeed': fanSpeed,
        'waterLevel': waterLevel,
        'lpgValue': lpgValue,
        'coValue': coValue,
        'notificationsEnabled': notificationsEnabled,
        'lastSeen': lastSeen.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'],
        name: json['name'],
        type: DeviceType.values[json['type']],
        ipAddress: json['ipAddress'],
        gpioPin: json['gpioPin'],
        roomId: json['roomId'],
        isOn: json['isOn'] ?? false,
        isOnline: json['isOnline'] ?? false,
        batteryLevel: json['batteryLevel'],
        hasBattery: json['hasBattery'] ?? false,
        brightness: json['brightness'] ?? 100,
        fanSpeed: json['fanSpeed'] ?? 1,
        waterLevel: json['waterLevel'] ?? 50,
        lpgValue: (json['lpgValue'] ?? 0).toDouble(),
        coValue: (json['coValue'] ?? 0).toDouble(),
        notificationsEnabled: json['notificationsEnabled'] ?? true,
        lastSeen: json['lastSeen'] != null
            ? DateTime.parse(json['lastSeen'])
            : DateTime.now(),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );

  bool get isStale =>
      DateTime.now().difference(lastSeen).inMinutes > 5;
}

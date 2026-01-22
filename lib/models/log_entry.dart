import 'package:flutter/material.dart';

enum LogType {
  deviceOn,
  deviceOff,
  warning,
  error,
  info,
  sync,
  threshold,
  connection,
}

extension LogTypeExtension on LogType {
  String get displayName {
    switch (this) {
      case LogType.deviceOn:
        return 'Device On';
      case LogType.deviceOff:
        return 'Device Off';
      case LogType.warning:
        return 'Warning';
      case LogType.error:
        return 'Error';
      case LogType.info:
        return 'Info';
      case LogType.sync:
        return 'Sync';
      case LogType.threshold:
        return 'Threshold';
      case LogType.connection:
        return 'Connection';
    }
  }

  Color get color {
    switch (this) {
      case LogType.deviceOn:
        return const Color(0xFF00E676);
      case LogType.deviceOff:
        return const Color(0xFFFF1744);
      case LogType.warning:
        return const Color(0xFFFFAB00);
      case LogType.error:
        return const Color(0xFFFF1744);
      case LogType.info:
        return const Color(0xFF00B0FF);
      case LogType.sync:
        return const Color(0xFF00E5FF);
      case LogType.threshold:
        return const Color(0xFFAA00FF);
      case LogType.connection:
        return const Color(0xFF76FF03);
    }
  }

  IconData get icon {
    switch (this) {
      case LogType.deviceOn:
        return Icons.power;
      case LogType.deviceOff:
        return Icons.power_off;
      case LogType.warning:
        return Icons.warning_amber;
      case LogType.error:
        return Icons.error_outline;
      case LogType.info:
        return Icons.info_outline;
      case LogType.sync:
        return Icons.sync;
      case LogType.threshold:
        return Icons.speed;
      case LogType.connection:
        return Icons.wifi;
    }
  }
}

class LogEntry {
  final String id;
  final DateTime timestamp;
  final String deviceId;
  final String deviceName;
  final LogType type;
  final String action;
  final String? details;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.deviceId,
    required this.deviceName,
    required this.type,
    required this.action,
    this.details,
  });

  LogEntry copyWith({
    String? id,
    DateTime? timestamp,
    String? deviceId,
    String? deviceName,
    LogType? type,
    String? action,
    String? details,
  }) {
    return LogEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      type: type ?? this.type,
      action: action ?? this.action,
      details: details ?? this.details,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'deviceId': deviceId,
        'deviceName': deviceName,
        'type': type.index,
        'action': action,
        'details': details,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        deviceId: json['deviceId'],
        deviceName: json['deviceName'],
        type: LogType.values[json['type']],
        action: json['action'],
        details: json['details'],
      );

  String toCSV() {
    return '${timestamp.toIso8601String()},$deviceName,${type.displayName},$action,${details ?? ''}';
  }
}

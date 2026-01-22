import 'package:flutter/material.dart';

enum RoomType {
  livingRoom,
  hall,
  kitchen,
  bedroom,
  garage,
  bathroom,
  office,
  custom,
}

extension RoomTypeExtension on RoomType {
  String get displayName {
    switch (this) {
      case RoomType.livingRoom:
        return 'Living Room';
      case RoomType.hall:
        return 'Hall';
      case RoomType.kitchen:
        return 'Kitchen';
      case RoomType.bedroom:
        return 'Bedroom';
      case RoomType.garage:
        return 'Garage';
      case RoomType.bathroom:
        return 'Bathroom';
      case RoomType.office:
        return 'Office';
      case RoomType.custom:
        return 'Custom';
    }
  }

  IconData get icon {
    switch (this) {
      case RoomType.livingRoom:
        return Icons.weekend_outlined;
      case RoomType.hall:
        return Icons.door_front_door_outlined;
      case RoomType.kitchen:
        return Icons.kitchen_outlined;
      case RoomType.bedroom:
        return Icons.bed_outlined;
      case RoomType.garage:
        return Icons.garage_outlined;
      case RoomType.bathroom:
        return Icons.bathroom_outlined;
      case RoomType.office:
        return Icons.computer_outlined;
      case RoomType.custom:
        return Icons.room_preferences_outlined;
    }
  }

  Color get color {
    switch (this) {
      case RoomType.livingRoom:
        return const Color(0xFF4CAF50);
      case RoomType.hall:
        return const Color(0xFF9C27B0);
      case RoomType.kitchen:
        return const Color(0xFFFF9800);
      case RoomType.bedroom:
        return const Color(0xFF2196F3);
      case RoomType.garage:
        return const Color(0xFF607D8B);
      case RoomType.bathroom:
        return const Color(0xFF00BCD4);
      case RoomType.office:
        return const Color(0xFF795548);
      case RoomType.custom:
        return const Color(0xFFE91E63);
    }
  }
}

class Room {
  final String id;
  String name;
  RoomType type;
  DateTime createdAt;

  Room({
    required this.id,
    required this.name,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Room copyWith({
    String? id,
    String? name,
    RoomType? type,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'],
        name: json['name'],
        type: RoomType.values[json['type']],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
}

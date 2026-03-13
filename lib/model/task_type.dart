import 'package:flutter/material.dart';

class TaskType {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isCustom;

  const TaskType({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'iconCodePoint': icon.codePoint,
    'iconFontFamily': icon.fontFamily,
    'colorValue': color.value,
    'isCustom': isCustom,
  };

  factory TaskType.fromMap(Map<String, dynamic> map) => TaskType(
    id: map['id'],
    name: map['name'],
    icon: IconData(map['iconCodePoint'],
        fontFamily: map['iconFontFamily'] ?? 'MaterialIcons'),
    color: Color(map['colorValue']),
    isCustom: map['isCustom'] ?? false,
  );
}

class DefaultTaskTypes {
  static const List<TaskType> values = [
    TaskType(id: 'work', name: 'Work', icon: Icons.work_rounded, color: Color(0xFF6366F1)),
    TaskType(id: 'personal', name: 'Personal', icon: Icons.person_rounded, color: Color(0xFF10B981)),
    TaskType(id: 'professional', name: 'Professional', icon: Icons.business_center_rounded, color: Color(0xFF3B82F6)),
    TaskType(id: 'family', name: 'Family', icon: Icons.family_restroom_rounded, color: Color(0xFFF59E0B)),
    TaskType(id: 'birthday', name: 'Birthday', icon: Icons.cake_rounded, color: Color(0xFFEC4899)),
    TaskType(id: 'health', name: 'Health', icon: Icons.favorite_rounded, color: Color(0xFFEF4444)),
    TaskType(id: 'finance', name: 'Finance', icon: Icons.account_balance_wallet_rounded, color: Color(0xFF8B5CF6)),
    TaskType(id: 'shopping', name: 'Shopping', icon: Icons.shopping_bag_rounded, color: Color(0xFFFF7849)),
  ];

  static TaskType? getById(String id) {
    try {
      return values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}

const List<IconData> availableIcons = [
  Icons.star_rounded,
  Icons.sports_soccer_rounded,
  Icons.school_rounded,
  Icons.music_note_rounded,
  Icons.directions_run_rounded,
  Icons.restaurant_rounded,
  Icons.travel_explore_rounded,
  Icons.home_rounded,
  Icons.pets_rounded,
  Icons.book_rounded,
  Icons.computer_rounded,
  Icons.fitness_center_rounded,
  Icons.local_hospital_rounded,
  Icons.emoji_events_rounded,
  Icons.volunteer_activism_rounded,
  Icons.construction_rounded,
];

const List<Color> availableColors = [
  Color(0xFF6366F1),
  Color(0xFF10B981),
  Color(0xFF3B82F6),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFFEF4444),
  Color(0xFF8B5CF6),
  Color(0xFFFF7849),
  Color(0xFF14B8A6),
  Color(0xFF84CC16),
  Color(0xFFF97316),
  Color(0xFF06B6D4),
];
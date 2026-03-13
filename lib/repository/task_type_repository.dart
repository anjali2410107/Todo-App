import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:todoappp/model/task_type.dart';

class TaskTypeRepository {
  static const String _kCustomTypesKey = 'custom_task_types';
  static final _uuid = Uuid();

  static Future<List<TaskType>> getAllTypes() async {
    final custom = await getCustomTypes();
    return [...DefaultTaskTypes.values, ...custom];
  }

  static Future<List<TaskType>> getCustomTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kCustomTypesKey) ?? [];
    return raw.map((e) => TaskType.fromMap(jsonDecode(e))).toList();
  }

  static Future<TaskType> addCustomType({
    required String name,
    required int iconCodePoint,
    required int colorValue,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kCustomTypesKey) ?? [];
    final newType = TaskType(
      id: _uuid.v4(),
      name: name,
      icon: IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
      color: Color(colorValue),
      isCustom: true,
    );
    raw.add(jsonEncode(newType.toMap()));
    await prefs.setStringList(_kCustomTypesKey, raw);
    return newType;
  }

  static Future<void> deleteCustomType(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kCustomTypesKey) ?? [];
    final updated = raw.where((e) {
      final map = jsonDecode(e) as Map<String, dynamic>;
      return map['id'] != id;
    }).toList();
    await prefs.setStringList(_kCustomTypesKey, updated);
  }

  static Future<TaskType?> getTypeById(String id) async {
    final def = DefaultTaskTypes.getById(id);
    if (def != null) return def;
    final custom = await getCustomTypes();
    try {
      return custom.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
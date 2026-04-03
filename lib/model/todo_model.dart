import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todoappp/model/subtask_model.dart';

enum TaskPriority {
  high,
  medium,
  low,
}

class TodoModel {
  final String id;
  final String title;
  final bool isCompleted;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? startDate;
  final String? taskTypeId;
  final List<SubTask> subtasks;

  TodoModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.startDate,
    this.taskTypeId,
    this.subtasks = const [],
  });

  int get completedSubtasks => subtasks.where((s) => s.isCompleted).length;
  int get totalSubtasks => subtasks.length;
  double get subtaskProgress =>
      totalSubtasks == 0 ? 0 : completedSubtasks / totalSubtasks;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'priority': priority.name,
      'dueDate': dueDate?.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'taskTypeId': taskTypeId,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
    };
  }

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    List<SubTask> subtasks = [];
    if (map['subtasks'] != null) {
      if (map['subtasks'] is List) {
        subtasks = (map['subtasks'] as List)
            .map((s) => SubTask.fromMap(Map<String, dynamic>.from(s)))
            .toList();
      }
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      if (value is DateTime) return value;
      return null;
    }

    return TodoModel(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title']?.toString() ?? '',
      isCompleted: map['isCompleted'] ?? false,
      priority: TaskPriority.values.firstWhere(
            (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      dueDate: parseDate(map['dueDate']),
      startDate: parseDate(map['startDate']),
      taskTypeId: map['taskTypeId']?.toString(),
      subtasks: subtasks,
    );
  }

  TodoModel copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? startDate,
    String? taskTypeId,
    List<SubTask>? subtasks,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      taskTypeId: taskTypeId ?? this.taskTypeId,
      subtasks: subtasks ?? this.subtasks,
    );
  }
}
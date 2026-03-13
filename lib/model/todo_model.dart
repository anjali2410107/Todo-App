enum TaskPriority {
  high,
  medium,
  low,
}

enum TaskFilter {
  all,
  overdue,
  completed,
  highPriority,
}

class TodoModel {
  final String id;
  final String title;
  final bool isCompleted;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? startDate;
  final String? taskTypeId;

  TodoModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.startDate,
    this.taskTypeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'priority': priority.name,
      'dueDate': dueDate?.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'taskTypeId': taskTypeId,
    };
  }

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'],
      title: map['title'],
      isCompleted: map['isCompleted'] ?? false,
      priority: TaskPriority.values.firstWhere(
            (e) => e.name == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      taskTypeId: map['taskTypeId'],
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
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      taskTypeId: taskTypeId ?? this.taskTypeId,
    );
  }
}
class SubTask {
  final String id;
  final String title;
  bool isCompleted;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
  };

  factory SubTask.fromMap(Map<String, dynamic> map) => SubTask(
    id: map['id'],
    title: map['title'],
    isCompleted: map['isCompleted'] ?? false,
  );
}
import 'package:hive/hive.dart';
import 'package:todoappp/model/todo_model.dart';

class TodoRepository {
  final Box box = Hive.box('todos');

  List<TodoModel> getTodos() {
    final data = box.values.toList();
    final List<TodoModel> todos = [];
    for (final e in data) {
      try {
        todos.add(TodoModel.fromMap(Map<String, dynamic>.from(e)));
      } catch (err) {
        print('Error parsing todo from Hive: $err');
        // Skip corrupted record
      }
    }
    return todos;
  }

  Future<void> addTodo(TodoModel todo) async {
    await box.put(todo.id, todo.toMap());
  }

  Future<void> deleteTodo(String id) async {
    await box.delete(id);
  }

  Future<void> toggleTodo(TodoModel todo) async {
    final updated = TodoModel(
      id: todo.id,
      title: todo.title,
      isCompleted: !todo.isCompleted,
      priority: todo.priority,
      dueDate: todo.dueDate,
      startDate: todo.startDate,
      taskTypeId: todo.taskTypeId,
      subtasks: todo.subtasks, // preserve subtasks
    );
    await box.put(todo.id, updated.toMap());
  }

  Future<void> updateTodo(TodoModel updatedTodo) async {
    await box.put(updatedTodo.id, updatedTodo.toMap());
  }

  Future<void> clearTodos() async {
    await box.clear();
  }
}
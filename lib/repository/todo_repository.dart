import 'package:hive/hive.dart';
import 'package:todoappp/model/todo_model.dart';
class TodoRepository {
  final Box box=Hive.box('todos');

  List<TodoModel> getTodos()
  {
    final data = box.values.toList();
    return data
        .map((e) => TodoModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
  Future<void> addTodo(TodoModel todo) async
  {
    await box.put(todo.id, todo.toMap());
  }
  Future<void> deleteTodo(String id)async
  {
    await box.delete(id);
  }
Future<void> toggleTodo(TodoModel todo)async
{
  final updated=TodoModel(
      id: todo.id,
      title: todo.title,
  isCompleted: !todo.isCompleted,
    priority: todo.priority,
    dueDate: todo.dueDate,
  );
  await box.put(todo.id,updated.toMap());
}
Future<void> updateTodo(TodoModel updatedTodo) async
{
  await box.put(updatedTodo.id, updatedTodo.toMap());
}
}
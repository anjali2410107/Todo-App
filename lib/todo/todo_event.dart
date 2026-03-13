part of 'todo_bloc.dart';

abstract class TodoEvent {}

class LoadTodos extends TodoEvent {}

class AddTodo extends TodoEvent {
  final String title;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? startDate;
  final String? taskTypeId;

  AddTodo(this.title, this.priority, this.dueDate, this.startDate,
      {this.taskTypeId});
}

class DeleteTodo extends TodoEvent {
  final String id;
  DeleteTodo(this.id);
}

class ToggleTodo extends TodoEvent {
  final TodoModel todo;
  ToggleTodo(this.todo);
}

class UpdateTodoEvent extends TodoEvent {
  final TodoModel updatedTodo;
  UpdateTodoEvent({required this.updatedTodo});
}
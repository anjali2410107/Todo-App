part of 'todo_bloc.dart';

abstract class TodoEvent {}
class LoadTodos extends TodoEvent{}
 class AddTodo extends TodoEvent
 {
   final String title;
   final TaskPriority priority;
   AddTodo(this.title,this.priority);
 }
 class DeleteTodo extends TodoEvent{
  final String id;
  DeleteTodo(this.id);
 }
  class ToggleTodo extends TodoEvent
  {
    final TodoModel todo;
    ToggleTodo(this.todo);
  }

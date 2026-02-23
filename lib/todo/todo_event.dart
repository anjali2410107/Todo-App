part of 'todo_bloc.dart';

abstract class TodoEvent {}
class LoadTodos extends TodoEvent{}
 class AddTodo extends TodoEvent
 {
   final String title;
   AddTodo(this.title);
 }
 class DeleteTodo extends TodoEvent{
  final String id;
  DeleteTodo(this.id);
 }
  class ToggleTodo extends TodoEvent
  {
    final TodoEvent todo;
    ToggleTodo(this.todo);
  }

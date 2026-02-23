part of 'todo_bloc.dart';

abstract class TodoState {}

class TodoLoded extends TodoState{}

class TodoLoaded extends TodoState
{
  final List<TodoModel> todos;
  TodoLoaded(this.todos);
}

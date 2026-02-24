import 'package:bloc/bloc.dart';
 import 'package:todoappp/model/todo_model.dart';
import 'package:todoappp/repository/todo_repository.dart';
import 'package:uuid/uuid.dart';

part 'todo_event.dart';
part 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository repository;
  final Uuid uuid =Uuid();

  TodoBloc(this.repository):super(TodoInitial())
  {
    on<LoadTodos>((event,emit)
    {
      final todos =repository.getTodos();
      emit(TodoLoaded(todos));
    });
    on<AddTodo>((event,emit)async
    {
      final todo=TodoModel(
          id: uuid.v4(),
          title: event.title,
          priority: event.priority
      );
      await repository.addTodo(todo);
      emit(TodoLoaded(repository.getTodos()));
    });

    on<DeleteTodo>((event,emit)async
    {
      await repository.deleteTodo(event.id);
      emit(TodoLoaded(repository.getTodos()));
    });

    on<ToggleTodo>((event,emit)
    async
        {
          await repository.toggleTodo(event.todo);
          emit(TodoLoaded(repository.getTodos()));
        }
    );
  }
}

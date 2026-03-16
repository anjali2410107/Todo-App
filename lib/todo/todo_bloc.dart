import 'package:bloc/bloc.dart';
import 'package:todoappp/core/services/streak_services.dart';
import 'package:todoappp/model/todo_model.dart';
import 'package:todoappp/repository/todo_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:todoappp/core/services/notification_service.dart';
part 'todo_event.dart';
part 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository repository;
  final Uuid uuid = Uuid();

  TodoBloc(this.repository) : super(TodoInitial()) {
    on<LoadTodos>((event, emit) async {
      final todos = repository.getTodos();
      for (final todo in todos) {
        if (!todo.isCompleted) {
          if (todo.dueDate != null) {
            await NotificationService.scheduleTaskReminders(
              taskId: todo.id,
              title: todo.title,
              dueDate: todo.dueDate!,
            );
          }
          if (todo.startDate != null) {
            await NotificationService.scheduleStartReminder(
              taskId: todo.id,
              title: todo.title,
              startDate: todo.startDate!,
            );
          }
        }
      }
      emit(TodoLoaded(todos));
    });

    on<AddTodo>((event, emit) async {
      final todo = TodoModel(
        id: uuid.v4(),
        title: event.title,
        priority: event.priority,
        dueDate: event.dueDate,
        startDate: event.startDate,
        taskTypeId: event.taskTypeId,
      );
      await repository.addTodo(todo);
      if (todo.dueDate != null) {
        await NotificationService.scheduleTaskReminders(
          taskId: todo.id,
          title: todo.title,
          dueDate: todo.dueDate!,
        );
      }
      if (todo.startDate != null) {
        await NotificationService.scheduleStartReminder(
          taskId: todo.id,
          title: todo.title,
          startDate: todo.startDate!,
        );
      }
      emit(TodoLoaded(repository.getTodos()));
    });

    on<DeleteTodo>((event, emit) async {
      await repository.deleteTodo(event.id);
      await NotificationService.cancelTaskReminders(event.id);
      await NotificationService.cancelStartReminder(event.id);
      emit(TodoLoaded(repository.getTodos()));
    });

    on<ToggleTodo>((event, emit) async {
      await repository.toggleTodo(event.todo);
      final isBeingCompleted = !event.todo.isCompleted;

      if (isBeingCompleted) {
        await StreakService.onTaskCompleted();
        await NotificationService.cancelTaskReminders(event.todo.id);
        await NotificationService.cancelStartReminder(event.todo.id);
      } else {
        await StreakService.onTaskUncompleted();
        if (event.todo.dueDate != null &&
            event.todo.dueDate!.isAfter(DateTime.now())) {
          await NotificationService.scheduleTaskReminders(
            taskId: event.todo.id,
            title: event.todo.title,
            dueDate: event.todo.dueDate!,
          );
        }
        if (event.todo.startDate != null &&
            event.todo.startDate!.isAfter(DateTime.now())) {
          await NotificationService.scheduleStartReminder(
            taskId: event.todo.id,
            title: event.todo.title,
            startDate: event.todo.startDate!,
          );
        }
      }
      emit(TodoLoaded(repository.getTodos()));
    });

    on<UpdateTodoEvent>((event, emit) async {
      await NotificationService.cancelTaskReminders(event.updatedTodo.id);
      await NotificationService.cancelStartReminder(event.updatedTodo.id);
      await repository.updateTodo(event.updatedTodo);
      if (event.updatedTodo.dueDate != null) {
        await NotificationService.scheduleTaskReminders(
          taskId: event.updatedTodo.id,
          title: event.updatedTodo.title,
          dueDate: event.updatedTodo.dueDate!,
        );
      }
      if (event.updatedTodo.startDate != null) {
        await NotificationService.scheduleStartReminder(
          taskId: event.updatedTodo.id,
          title: event.updatedTodo.title,
          startDate: event.updatedTodo.startDate!,
        );
      }
      emit(TodoLoaded(repository.getTodos()));
    });
  }
}
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:todoappp/core/services/streak_services.dart';
import 'package:todoappp/model/todo_model.dart';
import 'package:todoappp/repository/firestore_todo_repository.dart';
import 'package:todoappp/repository/todo_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:todoappp/core/services/notification_service.dart';

part 'todo_event.dart';
part 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository hiveRepository;
  final FirestoreTodoRepository firestoreRepository;
  final Uuid uuid = Uuid();
  StreamSubscription? _todosSubscription;
  
  final Map<String, int> _notificationCache = {};

  TodoBloc({required this.hiveRepository, required this.firestoreRepository})
      : super(TodoInitial()) {
    on<LoadTodos>((event, emit) async {
      final localTodos = hiveRepository.getTodos();
      emit(TodoLoaded(localTodos));

      try {
        final remoteTodos = await firestoreRepository.getTodos();
        if (remoteTodos.isEmpty && localTodos.isNotEmpty) {
          await firestoreRepository.migrateTodos(localTodos);
        }

        await _todosSubscription?.cancel();
        _todosSubscription = firestoreRepository
            .getTodosStream()
            .debounceTime(const Duration(milliseconds: 300))
            .listen((todos) {
          add(_UpdateTodosFromFirestore(todos));
        });
      } catch (e) {
        print("Firestore sync error: $e");
      }
    });

    on<_UpdateTodosFromFirestore>((event, emit) async {
      final todos = event.todos;
      
      for (final todo in todos) {
        final taskHash = Object.hash(todo.title, todo.dueDate, todo.startDate, todo.isCompleted);
        
        if (_notificationCache[todo.id] == taskHash) continue;
        _notificationCache[todo.id] = taskHash;

        if (!todo.isCompleted) {
          if (todo.dueDate != null && todo.dueDate!.isAfter(DateTime.now())) {
            await NotificationService.scheduleTaskReminders(
              taskId: todo.id,
              title: todo.title,
              dueDate: todo.dueDate!,
            );
          }
          if (todo.startDate != null && todo.startDate!.isAfter(DateTime.now())) {
            await NotificationService.scheduleStartReminder(
              taskId: todo.id,
              title: todo.title,
              startDate: todo.startDate!,
            );
          }
        } else {
          await NotificationService.cancelTaskReminders(todo.id);
          await NotificationService.cancelStartReminder(todo.id);
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
      
      // 1. Update local repository
      await hiveRepository.addTodo(todo);
      
      // 2. Emit UI update immediately (optimistic)
      final currentTodos = hiveRepository.getTodos();
      emit(TodoLoaded(currentTodos));

      // 3. Update Firestore in the background
      await firestoreRepository.addTodo(todo);
    });

    on<AddTodoModel>((event, emit) async {
      // 1. Update local
      await hiveRepository.addTodo(event.todo);
      
      // 2. Immediate UI update
      final currentTodos = hiveRepository.getTodos();
      emit(TodoLoaded(currentTodos));

      // 3. Cloud update
      await firestoreRepository.addTodo(event.todo);
    });

    on<DeleteTodo>((event, emit) async {
      _notificationCache.remove(event.id);
      
      // 1. Update local
      await hiveRepository.deleteTodo(event.id);
      
      // 2. Immediate UI update
      final currentTodos = hiveRepository.getTodos();
      emit(TodoLoaded(currentTodos));

      // 3. Cloud update
      await firestoreRepository.deleteTodo(event.id);
      await NotificationService.cancelTaskReminders(event.id);
      await NotificationService.cancelStartReminder(event.id);
    });

    on<ToggleTodo>((event, emit) async {
      final updatedTodo = event.todo.copyWith(isCompleted: !event.todo.isCompleted);
      
      // 1. Update local
      await hiveRepository.updateTodo(updatedTodo);
      
      // 2. Immediate UI update
      final currentTodos = hiveRepository.getTodos();
      emit(TodoLoaded(currentTodos));

      // 3. Stats & Cloud
      if (!event.todo.isCompleted) {
        await StreakService.onTaskCompleted();
      } else {
        await StreakService.onTaskUncompleted();
      }
      await firestoreRepository.toggleTodo(event.todo);
    });

    on<UpdateTodoEvent>((event, emit) async {
      // 1. Update local
      await hiveRepository.updateTodo(event.updatedTodo);
      
      // 2. Immediate UI update
      final currentTodos = hiveRepository.getTodos();
      emit(TodoLoaded(currentTodos));

      // 3. Cloud
      await firestoreRepository.updateTodo(event.updatedTodo);
    });

    on<ClearTodos>((event, emit) async {
      await _todosSubscription?.cancel();
      _todosSubscription = null;
      await hiveRepository.clearTodos();
      _notificationCache.clear();
      emit(TodoInitial());
    });
  }

  @override
  Future<void> close() {
    _todosSubscription?.cancel();
    return super.close();
  }
}

class _UpdateTodosFromFirestore extends TodoEvent {
  final List<TodoModel> todos;
  _UpdateTodosFromFirestore(this.todos);
}
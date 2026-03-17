import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todoappp/model/todo_model.dart';
import 'package:todoappp/repository/todo_repository.dart';
import 'package:todoappp/todo/todo_bloc.dart';

class MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  late MockTodoRepository mockRepository;
  late TodoBloc todoBloc;

  final testTodo = TodoModel(
    id: 'test-id-1',
    title: 'Test Task',
    priority: TaskPriority.medium,
  );

  final highPriorityTodo = TodoModel(
    id: 'test-id-2',
    title: 'Urgent Task',
    priority: TaskPriority.high,
  );

  setUp(() {
    mockRepository = MockTodoRepository();
    todoBloc = TodoBloc(mockRepository);
  });

  tearDown(() {
    todoBloc.close();
  });

  group('TodoBloc', () {
    // ── LoadTodos ──
    test('initial state is TodoInitial', () {
      expect(todoBloc.state, isA<TodoInitial>());
    });

    blocTest<TodoBloc, TodoState>(
      'emits [TodoLoaded] when LoadTodos is added',
      build: () {
        when(() => mockRepository.getTodos()).thenReturn([testTodo]);
        return TodoBloc(mockRepository);
      },
      act: (bloc) => bloc.add(LoadTodos()),
      expect: () => [
        isA<TodoLoaded>().having(
              (s) => s.todos.length,
          'todos length',
          1,
        ),
      ],
    );

    blocTest<TodoBloc, TodoState>(
      'emits [TodoLoaded] with empty list when no todos',
      build: () {
        when(() => mockRepository.getTodos()).thenReturn([]);
        return TodoBloc(mockRepository);
      },
      act: (bloc) => bloc.add(LoadTodos()),
      expect: () => [
        isA<TodoLoaded>().having(
              (s) => s.todos.isEmpty,
          'todos is empty',
          true,
        ),
      ],
    );

    // ── AddTodo ──
    blocTest<TodoBloc, TodoState>(
      'emits [TodoLoaded] with new todo after AddTodo',
      build: () {
        when(() => mockRepository.addTodo(any())).thenAnswer((_) async {});
        when(() => mockRepository.getTodos()).thenReturn([testTodo]);
        return TodoBloc(mockRepository);
      },
      act: (bloc) => bloc.add(
        AddTodo('Test Task', TaskPriority.medium, null, null),
      ),
      expect: () => [
        isA<TodoLoaded>().having(
              (s) => s.todos.isNotEmpty,
          'todos not empty',
          true,
        ),
      ],
    );

    // ── DeleteTodo ──
    blocTest<TodoBloc, TodoState>(
      'emits [TodoLoaded] with empty list after DeleteTodo',
      build: () {
        when(() => mockRepository.deleteTodo(any())).thenAnswer((_) async {});
        when(() => mockRepository.getTodos()).thenReturn([]);
        return TodoBloc(mockRepository);
      },
      act: (bloc) => bloc.add(DeleteTodo('test-id-1')),
      expect: () => [
        isA<TodoLoaded>().having(
              (s) => s.todos.isEmpty,
          'todos is empty',
          true,
        ),
      ],
    );

    // ── ToggleTodo ──
    blocTest<TodoBloc, TodoState>(
      'emits [TodoLoaded] after ToggleTodo',
      build: () {
        when(() => mockRepository.toggleTodo(any())).thenAnswer((_) async {});
        when(() => mockRepository.getTodos()).thenReturn([
          TodoModel(
            id: testTodo.id,
            title: testTodo.title,
            isCompleted: true,
            priority: testTodo.priority,
          ),
        ]);
        return TodoBloc(mockRepository);
      },
      act: (bloc) => bloc.add(ToggleTodo(testTodo)),
      expect: () => [
        isA<TodoLoaded>().having(
              (s) => s.todos.first.isCompleted,
          'todo is completed',
          true,
        ),
      ],
    );

    // ── UpdateTodoEvent ──
    blocTest<TodoBloc, TodoState>(
      'emits [TodoLoaded] with updated todo after UpdateTodoEvent',
      build: () {
        final updatedTodo = TodoModel(
          id: testTodo.id,
          title: 'Updated Title',
          priority: TaskPriority.high,
        );
        when(() => mockRepository.updateTodo(any())).thenAnswer((_) async {});
        when(() => mockRepository.getTodos()).thenReturn([updatedTodo]);
        return TodoBloc(mockRepository);
      },
      act: (bloc) => bloc.add(UpdateTodoEvent(
        updatedTodo: TodoModel(
          id: testTodo.id,
          title: 'Updated Title',
          priority: TaskPriority.high,
        ),
      )),
      expect: () => [
        isA<TodoLoaded>().having(
              (s) => s.todos.first.title,
          'updated title',
          'Updated Title',
        ),
      ],
    );

    // ── Undo Delete (AddTodoModel) ──
    blocTest<TodoBloc, TodoState>(
      'emits [TodoLoaded] with restored todo after AddTodoModel (undo)',
      build: () {
        when(() => mockRepository.addTodo(any())).thenAnswer((_) async {});
        when(() => mockRepository.getTodos()).thenReturn([testTodo]);
        return TodoBloc(mockRepository);
      },
      act: (bloc) => bloc.add(AddTodoModel(testTodo)),
      expect: () => [
        isA<TodoLoaded>().having(
              (s) => s.todos.first.id,
          'restored todo id',
          testTodo.id,
        ),
      ],
    );

    // ── Multiple todos ──
    blocTest<TodoBloc, TodoState>(
      'loads multiple todos correctly',
      build: () {
        when(() => mockRepository.getTodos())
            .thenReturn([testTodo, highPriorityTodo]);
        return TodoBloc(mockRepository);
      },
      act: (bloc) => bloc.add(LoadTodos()),
      expect: () => [
        isA<TodoLoaded>().having(
              (s) => s.todos.length,
          'todos length',
          2,
        ),
      ],
    );

    blocTest<TodoBloc, TodoState>(
      'high priority todo has correct priority',
      build: () {
        when(() => mockRepository.getTodos()).thenReturn([highPriorityTodo]);
        return TodoBloc(mockRepository);
      },
      act: (bloc) => bloc.add(LoadTodos()),
      expect: () => [
        isA<TodoLoaded>().having(
              (s) => s.todos.first.priority,
          'priority is high',
          TaskPriority.high,
        ),
      ],
    );
  });

  // ── TodoModel unit tests ──
  group('TodoModel', () {
    test('default isCompleted is false', () {
      final todo = TodoModel(id: '1', title: 'Test');
      expect(todo.isCompleted, false);
    });

    test('default priority is medium', () {
      final todo = TodoModel(id: '1', title: 'Test');
      expect(todo.priority, TaskPriority.medium);
    });

    test('toMap and fromMap round-trip', () {
      final original = TodoModel(
        id: 'abc',
        title: 'Round trip test',
        isCompleted: true,
        priority: TaskPriority.high,
      );
      final map = original.toMap();
      final restored = TodoModel.fromMap(map);
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.isCompleted, original.isCompleted);
      expect(restored.priority, original.priority);
    });

    test('subtaskProgress is 0 when no subtasks', () {
      final todo = TodoModel(id: '1', title: 'Test');
      expect(todo.subtaskProgress, 0.0);
    });

    test('copyWith preserves unspecified fields', () {
      final original = TodoModel(
        id: '1',
        title: 'Original',
        priority: TaskPriority.high,
      );
      final copy = original.copyWith(title: 'Updated');
      expect(copy.id, '1');
      expect(copy.title, 'Updated');
      expect(copy.priority, TaskPriority.high);
    });
  });
}
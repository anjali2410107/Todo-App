import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todoappp/model/todo_model.dart';
import 'package:todoappp/repository/todo_repository.dart';
import 'package:todoappp/repository/firestore_todo_repository.dart';
import 'package:todoappp/todo/todo_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHiveRepository extends Mock implements TodoRepository {}
class MockFirestoreRepository extends Mock implements FirestoreTodoRepository {}

void main() {
  late MockHiveRepository mockHiveRepository;
  late MockFirestoreRepository mockFirestoreRepository;
  late TodoBloc todoBloc;

  final testTodo = TodoModel(
    id: 'test-id-1',
    title: 'Test Task',
    priority: TaskPriority.medium,
  );



  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerFallbackValues();
  });

  setUp(() {
    mockHiveRepository = MockHiveRepository();
    mockFirestoreRepository = MockFirestoreRepository();
    
    // Default stubs
    when(() => mockFirestoreRepository.getTodos()).thenAnswer((_) async => []);
    when(() => mockFirestoreRepository.getTodosStream()).thenAnswer((_) => Stream.value([]));
    when(() => mockHiveRepository.getTodos()).thenReturn([]);

    todoBloc = TodoBloc(
      hiveRepository: mockHiveRepository,
      firestoreRepository: mockFirestoreRepository,
    );
  });

  tearDown(() {
    todoBloc.close();
  });

  group('TodoBloc', () {
    test('initial state is TodoInitial', () {
      expect(todoBloc.state, isA<TodoInitial>());
    });

    blocTest<TodoBloc, TodoState>(
      'emits [TodoLoaded] when LoadTodos is added (via stream update)',
      build: () {
        when(() => mockHiveRepository.getTodos()).thenReturn([]);
        when(() => mockFirestoreRepository.getTodos()).thenAnswer((_) async => []);
        when(() => mockFirestoreRepository.getTodosStream()).thenAnswer((_) => Stream.value([testTodo]));
        return TodoBloc(
          hiveRepository: mockHiveRepository,
          firestoreRepository: mockFirestoreRepository,
        );
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
      'AddTodo calls firestoreRepository.addTodo',
      build: () {
        when(() => mockFirestoreRepository.addTodo(any())).thenAnswer((_) async {});
        // Mock stream to keep state stable
        when(() => mockFirestoreRepository.getTodosStream()).thenAnswer((_) => const Stream.empty());
        return TodoBloc(
          hiveRepository: mockHiveRepository,
          firestoreRepository: mockFirestoreRepository,
        );
      },
      act: (bloc) => bloc.add(
        AddTodo('New Task', TaskPriority.medium, null, null, taskTypeId: null),
      ),
      verify: (_) {
        verify(() => mockFirestoreRepository.addTodo(any())).called(1);
      },
    );

    blocTest<TodoBloc, TodoState>(
      'DeleteTodo calls firestoreRepository.deleteTodo',
      build: () {
        when(() => mockFirestoreRepository.deleteTodo(any())).thenAnswer((_) async {});
        return TodoBloc(
          hiveRepository: mockHiveRepository,
          firestoreRepository: mockFirestoreRepository,
        );
      },
      act: (bloc) => bloc.add(DeleteTodo('test-id-1')),
      verify: (_) {
        verify(() => mockFirestoreRepository.deleteTodo('test-id-1')).called(1);
      },
    );

    blocTest<TodoBloc, TodoState>(
      'ToggleTodo calls firestoreRepository.toggleTodo',
      build: () {
        when(() => mockFirestoreRepository.toggleTodo(any())).thenAnswer((_) async {});
        return TodoBloc(
          hiveRepository: mockHiveRepository,
          firestoreRepository: mockFirestoreRepository,
        );
      },
      act: (bloc) => bloc.add(ToggleTodo(testTodo)),
      verify: (_) {
        verify(() => mockFirestoreRepository.toggleTodo(any())).called(1);
      },
    );
  });

  group('TodoModel', () {
    test('default values are correct', () {
      final todo = TodoModel(id: '1', title: 'Test');
      expect(todo.isCompleted, false);
      expect(todo.priority, TaskPriority.medium);
    });

    test('toMap and fromMap round-trip handles Timestamp (Firestore format)', () {
      final now = DateTime.now();
      final original = TodoModel(
        id: 'abc',
        title: 'Round trip',
        dueDate: now,
      );
      final map = original.toMap();
      // Ensure it's a Timestamp in the map
      expect(map['dueDate'], isA<Timestamp>());
      
      final restored = TodoModel.fromMap(map);
      // Compare by milliseconds to avoid micromillisecond precision issues in some environments
      expect(restored.dueDate?.millisecondsSinceEpoch, original.dueDate?.millisecondsSinceEpoch);
    });
  });
}

// Helper for Mocktail to handle any()
class FakeTodoModel extends Fake implements TodoModel {}

void registerFallbackValues() {
  registerFallbackValue(FakeTodoModel());
}
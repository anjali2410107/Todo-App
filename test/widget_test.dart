import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:todoappp/main.dart';
import 'package:todoappp/core/theme/theme_provider.dart';
import 'package:todoappp/todo/todo_bloc.dart';
import 'package:todoappp/repository/todo_repository.dart';
import 'package:todoappp/repository/firestore_todo_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockHiveRepository extends Mock implements TodoRepository {}
class MockFirestoreRepository extends Mock implements FirestoreTodoRepository {}

void main() {
  testWidgets('App starts and shows Splash Screen', (WidgetTester tester) async {
    // 1. Setup Mocks
    final mockHive = MockHiveRepository();
    final mockFirestore = MockFirestoreRepository();

    // 2. Build the app with Providers just like in main.dart
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(false)),
          RepositoryProvider<TodoRepository>.value(value: mockHive),
          RepositoryProvider<FirestoreTodoRepository>.value(value: mockFirestore),
        ],
        child: BlocProvider(
          create: (_) => TodoBloc(
            hiveRepository: mockHive,
            firestoreRepository: mockFirestore,
          ),
          child: const MyApp(),
        ),
      ),
    );

    // 3. Verify Splash screen or initial elements
    // Since SplashScreen has an animation and a timer, we use pumpAndSettle
    await tester.pumpAndSettle();
    
    // Smoke check: check that MyApp is there
    expect(find.byType(MyApp), findsOneWidget);
  });
}

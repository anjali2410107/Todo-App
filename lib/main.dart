import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:todoappp/core/theme/theme_provider.dart';
import 'package:todoappp/repository/todo_repository.dart';
import 'package:todoappp/screens/splash_screen.dart';
import 'package:todoappp/todo/todo_bloc.dart';
import 'auth/auth_service.dart';
import 'core/services/focus_background_service.dart';
import 'core/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:todoappp/repository/firestore_todo_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthService.initializeGoogleSignIn();
  await initializeBackgroundService();
  await Hive.initFlutter();
  await Hive.openBox('todos');
  await NotificationService.init();

  final isDarkMode = await ThemeProvider.getSavedTheme();
  final hiveRepository = TodoRepository();
  final firestoreRepository = FirestoreTodoRepository();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(isDarkMode),
      child: BlocProvider(
        create: (_) => TodoBloc(
          hiveRepository: hiveRepository,
          firestoreRepository: firestoreRepository,
        ),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeProvider.lightTheme(),
      darkTheme: ThemeProvider.darkTheme(),
      home: const SplashScreen(),
    );
  }
}
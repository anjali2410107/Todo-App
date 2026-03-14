import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todoappp/repository/todo_repository.dart';
import 'package:todoappp/screens/main_screen.dart';
import 'package:todoappp/screens/onboarding_screen.dart';
import 'package:todoappp/todo/todo_bloc.dart';
import 'core/services/focus_background_service.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackgroundService();
  await Hive.initFlutter();
  await Hive.openBox('todos');
  await NotificationService.init();

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;

  final repository = TodoRepository();

  runApp(BlocProvider(
    create: (_) => TodoBloc(repository),
    child: MyApp(onboardingDone: onboardingDone),
  ));
}

class MyApp extends StatelessWidget {
  final bool onboardingDone;
  const MyApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: onboardingDone ? const MainScreen() : const OnboardingScreen(),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:todoappp/screens/home_screen.dart';
import 'package:todoappp/screens/calender_screen.dart';
import 'package:todoappp/screens/focus_screen.dart';
import 'package:todoappp/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<SettingsScreenState> _settingsKey = GlobalKey<SettingsScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const CalendarScreen(),
      const FocusScreen(),
      SettingsScreen(key: _settingsKey),
    ];
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    if (index == 3) {
      _settingsKey.currentState?.reloadStreak();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline_rounded),
            activeIcon: Icon(Icons.check_circle_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            activeIcon: Icon(Icons.timer_rounded),
            label: 'Focus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
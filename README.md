# 🎯 TodoAppp — Premium Productivity & Focus Companion

[![Flutter Version](https://img.shields.io/badge/Flutter-3.11.0%2B-02569B?logo=flutter&style=flat-square)](https://flutter.dev)
[![State Management](https://img.shields.io/badge/State--Management-BLoC%20%7C%20Provider-8B5CF6?style=flat-square)](https://pub.dev/packages/flutter_bloc)
[![Database](https://img.shields.io/badge/Database-Hive%20%7C%20Firestore-10B981?style=flat-square)](https://pub.dev/packages/hive)
[![Build Status](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3B82F6?logo=android&logoColor=white&style=flat-square)](#)

A feature-rich, high-fidelity productivity hub and Pomodoro assistant built using **Flutter**. By marrying granular task management, habit streak triggers, and deep work focus timers, **TodoAppp** stands out as a premium developer-focused productivity manager. Built on the core principles of **Clean Architecture** and **reactive state management (BLoC)**, this project demonstrates offline-first reliability synchronized instantly to the cloud.

---

## ✨ Features

### 🔄 Offline-First & Cloud Sync
* **Hive Local DB:** Save, edit, and toggle tasks with instantaneous speed, even without internet coverage.
* **Firestore Syncing:** Automatically uploads local database updates to Google Cloud Firestore on connectivity. Includes seamless initial database migrations.

### 🔑 Secure Authentication
* Built with **Firebase Auth** supporting secure email-and-password profiles.
* Single-tap **Google Sign-In** for simplified onboarding.

### 🎯 Deep Work & Focus Timer
* Configurable multi-phase timer supporting standard techniques:
  * **Ultradian Rhythm:** 90m focus, 20m break
  * **52/17 Rule:** 52m focus, 17m break
  * **45/10 Rule:** 45m focus, 10m break
  * **Pomodoro Extended:** Split sessions with short auto-breaks
  * **Custom Focus:** Set custom focus & break intervals.
* **Persistent Foreground Service:** Continues running and ticking down in your device's status bar even when the app is completely backgrounded or closed.
* **Vibration & Haptics:** Custom haptic feedback alerts on session phase transitions.

### 📊 Interactive Analytics & Dashboard
* Core stats counting completed sessions, today's focus minutes, and overall tasks.
* Visual dashboards utilizing `fl_chart`:
  * Completion rate dials and linear loaders.
  * Bar charts comparing Completed vs Pending tasks.
  * Task priority distribution metrics.

### 📅 Advanced Scheduler & Calendar
* High-fidelity interactive calendar layout utilizing `table_calendar`.
* Seamlessly view, schedule, and navigate tasks by target dates.

### 🔔 Smart Reminders & Local Notifications
* Custom notifications triggered via `flutter_local_notifications`.
* Automated scheduling of reminders before task start times and final deadlines.

### 🎨 Adaptive Aesthetics & Dark Mode
* Harmonious design built with vibrant HSL color tokens (Indigo, Emerald, Amber, Rose).
* Smooth dynamic switches between premium Light and Dark themes, automatically persisting choices using local storage.

---

## 🛠️ Tech Stack & Dependencies

* **Framework:** [Flutter SDK](https://flutter.dev) (Dart)
* **State Management:** `flutter_bloc` (v9.1.1) & `bloc` (v9.2.0)
* **Local Storage:** `hive_flutter` (v1.1.0) & `shared_preferences` (v2.5.4)
* **Backend Integration:** `firebase_core`, `cloud_firestore`, `firebase_auth`, `google_sign_in`
* **Background Tasks:** `flutter_background_service` (v5.1.0)
* **Local Notifications:** `flutter_local_notifications` (v20.1.0)
* **Calendar:** `table_calendar` (v3.1.2)
* **Charts:** `fl_chart` (v1.1.1)
* **Reactive Extensions:** `rxdart` (v0.28.0)
* **Utility Libraries:** `uuid`, `timezone`, `equatable`

---

## 📁 Repository Structure

```
lib/
├── auth/                       # Firebase Auth & Google Sign-In helper methods
│   └── auth_service.dart
├── core/
│   ├── services/
│   │   ├── focus_background_service.dart  # Native background execution details
│   │   ├── notification_service.dart      # Scheduled local notification alarms
│   │   └── streak_services.dart           # User streak & habit logic computations
│   └── theme/
│       ├── app_colors.dart                # Premium dynamic HSL theme tokens
│       └── theme_provider.dart            # Multi-theme state provider
├── model/
│   ├── subtask_model.dart                 # Checklist items for parent tasks
│   ├── task_type.dart                     # Custom & preset categories (Work, Personal, etc.)
│   └── todo_model.dart                    # Comprehensive Todo entity definition
├── repository/
│   ├── todo_repository.dart               # Local Hive database interface
│   └── firestore_todo_repository.dart     # Cloud Firestore collection stream & sync
├── todo/                                  # BLoC logic for loading/creating/deleting tasks
│   ├── todo_bloc.dart
│   ├── todo_event.dart
│   └── todo_state.dart
├── screens/                               # High-fidelity user screens
│   ├── splash_screen.dart                 # Initial loading & entry controller
│   ├── onboarding_screen.dart             # Onboarding tour slides
│   ├── login_screen.dart                  # Authentication forms & Google Login trigger
│   ├── main_screen.dart                   # Bottom navigation framework
│   ├── home_screen.dart                   # Main dashboard listing and creating tasks
│   ├── calender_screen.dart               # Calendar navigation and task planning
│   ├── focus_screen.dart                  # Focus timers, setup tools & history lists
│   ├── stats_screen.dart                  # Interactive charts and performance reports
│   └── task_detail_screen.dart            # Subtask editor, categories and deadline modifications
├── firebase_options.dart                  # Generated Firebase options for platforms
└── main.dart                              # Application initialization and app bootstrapper
```

---

## 🚀 Getting Started

### 📋 Prerequisites
Ensure you have the following installed on your machine:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `3.11.0` or higher)
* [Dart SDK](https://dart.dev/get-started)
* Android Studio / Xcode (for mobile emulators)

### 📲 Running Locally
1. **Clone the Repository:**
   ```bash
   git clone https://github.com/your-username/todoappp.git
   cd todoappp
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Initialize App Splash & Icons (Optional):**
   ```bash
   flutter pub run flutter_launcher_icons:main
   flutter pub run flutter_native_splash:create
   ```

4. **Connect to Your Firebase Project:**
   * Run the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli) tool to automatically configure platform targets:
     ```bash
     flutterfire configure
     ```
   * Ensure that Google Sign-in is enabled in your Firebase console under *Build > Authentication > Sign-in method*.
   * Ensure the SHA-1 fingerprints are added to your Firebase project settings (for Android Google Sign-In).

5. **Run the Project:**
   ```bash
   flutter run
   ```

---

## 🔒 Firebase Configuration Details
To set up Firestore sync manually:
1. Create a Firebase project at the [Firebase Console](https://console.firebase.google.com/).
2. Enable **Cloud Firestore** in test or production mode.
3. Enable **Email/Password** and **Google** providers under authentication.
4. Replace the configuration in [firebase_options.dart](file:///c:/todoapp/todoappp/lib/firebase_options.dart) or execute `flutterfire configure` to overwrite it with your credentials.

---

## 🤝 Contribution Guidelines
Contributions are welcome! Please fork this repository and submit a pull request for any features, fixes, or styling optimizations. Feel free to open issues to report bugs or request new layout capabilities.

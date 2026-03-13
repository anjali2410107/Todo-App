import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kChannelId        = 'focus_timer_channel';
const String _kChannelName      = 'Focus Timer';
const String _kAlertChannelId   = 'focus_alert_channel';
const String _kAlertChannelName = 'Focus Alerts';

const int _kFgNotifId       = 8888;
const int _kChunkNotifId    = 8889;
const int _kFinishNotifId   = 8890;
const int _kBreakEndNotifId = 8891;
const int _kBreakWarnNotifId= 8892;

const String _kEndTimeKey       = 'focus_end_time';
const String _kPhaseKey         = 'focus_phase';
const String _kChunksKey        = 'focus_chunks';
const String _kCurrentChunkKey  = 'focus_current_chunk';
const String _kSessionMinsKey   = 'focus_session_mins';
const String _kBreakMinsKey     = 'focus_break_mins';
const String _kWaitingForUserKey= 'focus_waiting_for_user';

Future<void> initializeBackgroundService() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;

  final plugin = FlutterLocalNotificationsPlugin();

  const timerChannel = AndroidNotificationChannel(
    _kChannelId, _kChannelName,
    description: 'Live focus timer countdown in status bar',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
    showBadge: false,
  );

  const alertChannel = AndroidNotificationChannel(
    _kAlertChannelId, _kAlertChannelName,
    description: 'Focus timer phase change alerts',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(timerChannel);
  await plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(alertChannel);

  final service = FlutterBackgroundService();
  await service.configure(
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onServiceStart,
    ),
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: _kChannelId,
      initialNotificationTitle: 'Focus Timer',
      initialNotificationContent: 'Starting…',
      foregroundServiceNotificationId: _kFgNotifId,
      foregroundServiceTypes: [AndroidForegroundType.specialUse],
    ),
  );
}

@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  List<Map<String, dynamic>> chunks = [];
  int currentChunkIndex = prefs.getInt(_kCurrentChunkKey) ?? 0;
  String phase          = prefs.getString(_kPhaseKey) ?? 'idle';
  int endMs             = prefs.getInt(_kEndTimeKey) ?? 0;
  bool waitingForUser   = prefs.getBool(_kWaitingForUserKey) ?? false;
  bool breakWarnFired   = false;

  final chunksJson = prefs.getString(_kChunksKey);
  if (chunksJson != null) {
    chunks = List<Map<String, dynamic>>.from(jsonDecode(chunksJson));
  }

  if (phase == 'idle' || chunks.isEmpty || endMs == 0) {
    service.stopSelf();
    return;
  }

  if (service is AndroidServiceInstance) {
    final now       = DateTime.now().millisecondsSinceEpoch;
    final remaining = ((endMs - now) / 1000).ceil().clamp(0, 999999);
    final mm        = (remaining ~/ 60).toString().padLeft(2, '0');
    final ss        = (remaining % 60).toString().padLeft(2, '0');
    final label     = phase == 'focusing' ? '🎯 Focusing' : '☕ Break';
    service.setForegroundNotificationInfo(
      title: waitingForUser ? '⏸ Ready to focus?' : '$label — $mm:$ss',
      content: waitingForUser ? 'Tap to start your next focus session' : 'Tap to return to the app',
    );
  }

  service.on('stopService').listen((_) => service.stopSelf());

  service.on('userResumedFocus').listen((data) async {
    if (data == null) return;
    currentChunkIndex = data['currentChunkIndex'] ?? currentChunkIndex;
    phase             = data['phase'] ?? phase;
    endMs             = data['endMs'] ?? endMs;
    waitingForUser    = false;
    breakWarnFired    = false;

    final p = await SharedPreferences.getInstance();
    await p.setBool(_kWaitingForUserKey, false);
  });

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (phase == 'idle') {
      timer.cancel();
      service.stopSelf();
      return;
    }

    if (waitingForUser) {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: '⏸ Ready to focus?',
          content: 'Open the app to start your next focus session',
        );
      }
      service.invoke('waitingForUser', {'currentChunkIndex': currentChunkIndex});
      return;
    }

    final now     = DateTime.now().millisecondsSinceEpoch;
    int remaining = ((endMs - now) / 1000).ceil();

    if (phase == 'onBreak' && remaining == 30 && !breakWarnFired) {
      breakWarnFired = true;
      await plugin.show(
        id: _kBreakWarnNotifId,
        title: '⏰ Break ending soon',
        body: '30 seconds left on your break. Get ready to focus!',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _kAlertChannelId, _kAlertChannelName,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
      );
    }

    if (remaining <= 0) {
      final nextIndex = currentChunkIndex + 1;

      if (nextIndex >= chunks.length) {
        timer.cancel();

        final p = await SharedPreferences.getInstance();
        await p.setString(_kPhaseKey, 'idle');
        await p.remove(_kEndTimeKey);
        await p.setBool(_kWaitingForUserKey, false);

        await plugin.show(
          id: _kFinishNotifId,
          title: '🎉 Session Complete!',
          body: 'Amazing work! Your entire focus session is done.',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _kAlertChannelId, _kAlertChannelName,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
          ),
        );

        service.invoke('sessionFinished', {});
        service.stopSelf();
        return;
      }

      final nextChunk   = chunks[nextIndex];
      final nextIsFocus = nextChunk['isFocus'] as bool;
      final nextMins    = nextChunk['minutes'] as int;

      if (!nextIsFocus) {
        currentChunkIndex = nextIndex;
        phase             = 'onBreak';
        endMs             = DateTime.now().millisecondsSinceEpoch + (nextMins * 60 * 1000);
        remaining         = nextMins * 60;
        breakWarnFired    = false;

        final p = await SharedPreferences.getInstance();
        await p.setInt(_kCurrentChunkKey, currentChunkIndex);
        await p.setString(_kPhaseKey, phase);
        await p.setInt(_kEndTimeKey, endMs);

        service.invoke('chunkChanged', {
          'currentChunkIndex': currentChunkIndex,
          'phase': phase,
          'secondsLeft': remaining,
        });

        await plugin.show(
          id: _kChunkNotifId,
          title: 'Break Time! 🎉',
          body: 'Great work! Take a $nextMins-minute break.',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _kAlertChannelId, _kAlertChannelName,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
          ),
        );
      }

      else {
        currentChunkIndex = nextIndex;
        waitingForUser    = true;

        final p = await SharedPreferences.getInstance();
        await p.setInt(_kCurrentChunkKey, currentChunkIndex);
        await p.setString(_kPhaseKey, 'waitingForUser');
        await p.setBool(_kWaitingForUserKey, true);
        await p.remove(_kEndTimeKey);

        service.invoke('waitingForUser', {'currentChunkIndex': currentChunkIndex});

        await plugin.show(
          id: _kBreakEndNotifId,
          title: '☕ Break\'s over! Ready to focus?',
          body: 'Tap to start your next focus session.',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _kAlertChannelId, _kAlertChannelName,
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
            iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
          ),
        );
        return;
      }
    }

    final mm    = (remaining ~/ 60).toString().padLeft(2, '0');
    final ss    = (remaining % 60).toString().padLeft(2, '0');
    final label = phase == 'focusing' ? '🎯 Focusing' : '☕ Break';

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: '$label — $mm:$ss',
        content: 'Tap to return to the app',
      );
    }

    service.invoke('timerUpdate', {
      'secondsLeft': remaining,
      'phase': phase,
      'currentChunkIndex': currentChunkIndex,
    });
  });
}

class FocusTimerService {
  static final _service = FlutterBackgroundService();

  static Future<void> startTimer({
    required int durationSeconds,
    required String phase,
    required int sessionMins,
    required int breakMins,
    required int currentChunkIndex,
    required List<Map<String, dynamic>> chunks,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final endMs = DateTime.now().millisecondsSinceEpoch + (durationSeconds * 1000);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kEndTimeKey, endMs);
    await prefs.setString(_kPhaseKey, phase);
    await prefs.setInt(_kSessionMinsKey, sessionMins);
    await prefs.setInt(_kBreakMinsKey, breakMins);
    await prefs.setInt(_kCurrentChunkKey, currentChunkIndex);
    await prefs.setString(_kChunksKey, jsonEncode(chunks));
    await prefs.setBool(_kWaitingForUserKey, false);

    final running = await _service.isRunning();
    if (running) {
      _service.invoke('stopService');
      await Future.delayed(const Duration(milliseconds: 600));
    }
    await _service.startService();
  }

  static Future<void> resumeFocusAfterBreak({
    required int durationSeconds,
    required int currentChunkIndex,
    required List<Map<String, dynamic>> chunks,
    required int sessionMins,
    required int breakMins,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final endMs = DateTime.now().millisecondsSinceEpoch + (durationSeconds * 1000);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kEndTimeKey, endMs);
    await prefs.setString(_kPhaseKey, 'focusing');
    await prefs.setInt(_kCurrentChunkKey, currentChunkIndex);
    await prefs.setBool(_kWaitingForUserKey, false);

    final running = await _service.isRunning();
    if (running) {
      _service.invoke('userResumedFocus', {
        'currentChunkIndex': currentChunkIndex,
        'phase': 'focusing',
        'endMs': endMs,
      });
    } else {
      await prefs.setString(_kChunksKey, jsonEncode(chunks));
      await prefs.setInt(_kSessionMinsKey, sessionMins);
      await prefs.setInt(_kBreakMinsKey, breakMins);
      await _service.startService();
    }
  }

  static Future<void> stopTimer() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _service.invoke('stopService');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPhaseKey, 'idle');
    await prefs.remove(_kEndTimeKey);
    await prefs.remove(_kChunksKey);
    await prefs.remove(_kCurrentChunkKey);
    await prefs.setBool(_kWaitingForUserKey, false);
  }

  static Future<Map<String, dynamic>?> getTimerState() async {
    final prefs      = await SharedPreferences.getInstance();
    final phase      = prefs.getString(_kPhaseKey);
    final chunksJson = prefs.getString(_kChunksKey);
    final chunkIndex = prefs.getInt(_kCurrentChunkKey);
    final waitingForUser = prefs.getBool(_kWaitingForUserKey) ?? false;

    if (phase == null || phase == 'idle') return null;

    List<Map<String, dynamic>>? chunks;
    if (chunksJson != null) {
      chunks = List<Map<String, dynamic>>.from(jsonDecode(chunksJson));
    }

    if (waitingForUser || phase == 'waitingForUser') {
      return {
        'secondsLeft': 0,
        'phase': 'waitingForUser',
        'chunkIndex': chunkIndex ?? 0,
        'chunks': chunks,
        'sessionMins': prefs.getInt(_kSessionMinsKey) ?? 0,
        'breakMins': prefs.getInt(_kBreakMinsKey) ?? 0,
        'waitingForUser': true,
      };
    }

    final endMs = prefs.getInt(_kEndTimeKey);
    if (endMs == null) return null;

    final remaining = ((endMs - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
    if (remaining <= 0) return null;

    return {
      'secondsLeft': remaining,
      'phase': phase,
      'chunkIndex': chunkIndex ?? 0,
      'chunks': chunks,
      'sessionMins': prefs.getInt(_kSessionMinsKey) ?? 0,
      'breakMins': prefs.getInt(_kBreakMinsKey) ?? 0,
      'waitingForUser': false,
    };
  }

  static Stream<Map<String, dynamic>?> get timerStream {
    if (!Platform.isAndroid && !Platform.isIOS) return const Stream.empty();
    return _service.on('timerUpdate');
  }

  static Stream<Map<String, dynamic>?> get chunkChangedStream {
    if (!Platform.isAndroid && !Platform.isIOS) return const Stream.empty();
    return _service.on('chunkChanged');
  }

  static Stream<Map<String, dynamic>?> get sessionFinishedStream {
    if (!Platform.isAndroid && !Platform.isIOS) return const Stream.empty();
    return _service.on('sessionFinished');
  }

  static Stream<Map<String, dynamic>?> get waitingForUserStream {
    if (!Platform.isAndroid && !Platform.isIOS) return const Stream.empty();
    return _service.on('waitingForUser');
  }
}
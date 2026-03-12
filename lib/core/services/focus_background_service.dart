import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kChannelId = 'focus_timer_channel';
const String _kChannelName = 'Focus Timer';
const int _kFgNotifId = 8888;
const String _kEndTimeKey = 'focus_end_time';
const String _kPhaseKey = 'focus_phase';
const String _kChunksKey = 'focus_chunks';
const String _kCurrentChunkKey = 'focus_current_chunk';
const String _kSessionMinsKey = 'focus_session_mins';
const String _kBreakMinsKey = 'focus_break_mins';

Future<void> initializeBackgroundService() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    _kChannelId,
    _kChannelName,
    description: 'Shows live focus-timer countdown',
    importance: Importance.low,
  );

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

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
      initialNotificationContent: 'Timer running…',
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

  service.on('stopService').listen((_) => service.stopSelf());

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    final prefs = await SharedPreferences.getInstance();
    final endMs = prefs.getInt(_kEndTimeKey);
    final phase = prefs.getString(_kPhaseKey) ?? 'idle';
    final currentChunkIndex = prefs.getInt(_kCurrentChunkKey) ?? 0;
    final chunksJson = prefs.getString(_kChunksKey);

    if (endMs == null || phase == 'idle') {
      timer.cancel();
      service.stopSelf();
      return;
    }

    final remaining = DateTime.fromMillisecondsSinceEpoch(endMs)
        .difference(DateTime.now())
        .inSeconds;

    if (remaining <= 0) {
      timer.cancel();

      List<Map<String, dynamic>> chunks = [];
      if (chunksJson != null) {
        chunks = List<Map<String, dynamic>>.from(jsonDecode(chunksJson));
      }

      final nextChunkIndex = currentChunkIndex + 1;
      final hasNextChunk = nextChunkIndex < chunks.length;

      if (hasNextChunk) {
        final nextChunk = chunks[nextChunkIndex];
        final nextIsFocus = nextChunk['isFocus'] as bool;
        final nextMins = nextChunk['minutes'] as int;
        final nextPhase = nextIsFocus ? 'focusing' : 'onBreak';

        final newEndTime =
        DateTime.now().add(Duration(seconds: nextMins * 60));
        await prefs.setInt(_kEndTimeKey, newEndTime.millisecondsSinceEpoch);
        await prefs.setString(_kPhaseKey, nextPhase);
        await prefs.setInt(_kCurrentChunkKey, nextChunkIndex);

        await plugin.show(
          id: _kFgNotifId + 1,
          title: nextIsFocus ? 'Back to Focus! 💪' : 'Break Time! 🎉',
          body: nextIsFocus
              ? "Break's over. Let's get back to it!"
              : 'Great work! Take a $nextMins-minute break.',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _kChannelId,
              _kChannelName,
              channelDescription: 'Focus timer notifications',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );

        service.invoke('chunkChanged', {
          'currentChunkIndex': nextChunkIndex,
          'phase': nextPhase,
          'secondsLeft': nextMins * 60,
        });
      } else {
        service.stopSelf();
        await prefs.setString(_kPhaseKey, 'idle');
        await prefs.remove(_kEndTimeKey);

        await plugin.show(
          id: _kFgNotifId + 2,
          title: '🎉 Session Complete!',
          body: 'Amazing work! Your focus session is done.',
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _kChannelId,
              _kChannelName,
              channelDescription: 'Focus timer notifications',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
      return;
    }

    final mm = (remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (remaining % 60).toString().padLeft(2, '0');
    final label = phase == 'focusing' ? '🎯 Focusing' : '☕ Break';

    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: '$label — $mm:$ss remaining',
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
    final prefs = await SharedPreferences.getInstance();
    final endTime = DateTime.now().add(Duration(seconds: durationSeconds));

    await prefs.setInt(_kEndTimeKey, endTime.millisecondsSinceEpoch);
    await prefs.setString(_kPhaseKey, phase);
    await prefs.setInt(_kSessionMinsKey, sessionMins);
    await prefs.setInt(_kBreakMinsKey, breakMins);
    await prefs.setInt(_kCurrentChunkKey, currentChunkIndex);
    await prefs.setString(_kChunksKey, jsonEncode(chunks));

    final running = await _service.isRunning();
    if (!running) await _service.startService();
  }

  static Future<void> stopTimer() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _service.invoke('stopService');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEndTimeKey);
    await prefs.setString(_kPhaseKey, 'idle');
    await prefs.remove(_kChunksKey);
    await prefs.remove(_kCurrentChunkKey);
  }

  static Future<int?> getRemainingSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final endMs = prefs.getInt(_kEndTimeKey);
    if (endMs == null) return null;
    final remaining = DateTime.fromMillisecondsSinceEpoch(endMs)
        .difference(DateTime.now())
        .inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  static Future<String?> getSavedPhase() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kPhaseKey);
  }

  static Future<int?> getSavedSessionMins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kSessionMinsKey);
  }

  static Future<int?> getSavedBreakMins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kBreakMinsKey);
  }

  static Future<int?> getSavedChunkIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kCurrentChunkKey);
  }

  static Future<List<Map<String, dynamic>>?> getSavedChunks() async {
    final prefs = await SharedPreferences.getInstance();
    final chunksJson = prefs.getString(_kChunksKey);
    if (chunksJson == null) return null;
    return List<Map<String, dynamic>>.from(jsonDecode(chunksJson));
  }

  static Stream<Map<String, dynamic>?> get timerStream {
    if (!Platform.isAndroid && !Platform.isIOS) return const Stream.empty();
    return _service.on('timerUpdate');
  }

  static Stream<Map<String, dynamic>?> get chunkChangedStream {
    if (!Platform.isAndroid && !Platform.isIOS) return const Stream.empty();
    return _service.on('chunkChanged');
  }
}
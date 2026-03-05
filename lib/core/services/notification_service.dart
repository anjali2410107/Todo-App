import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
class NotificationService{
  static final FlutterLocalNotificationsPlugin _notifications=
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async{
    tz_data.initializeTimeZones();
tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    const androidSettings=AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings=InitializationSettings(
      android: androidSettings,
    );
    await _notifications.initialize(settings: settings);
    await _notifications
    .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
    ?.requestNotificationsPermission();
  }
  static int _generateId(String taskId,int minutesBefore)
  {
    return taskId.hashCode+minutesBefore;
  }
  static Future<void> scheduleTaskReminders({
    required String taskId,
    required String title,
    required DateTime dueDate,
  }) async{
    final now=DateTime.now();
    final reminderDurations=[
      const Duration(hours: 24),
      const Duration(hours: 1),
      const Duration(minutes: 2),
    ];

    for(final duration in reminderDurations)
    {
      final reminderTime=dueDate.subtract(duration);
      if(reminderTime.isAfter(now))
      {
        await _notifications.zonedSchedule(
          id:_generateId(taskId,duration.inMinutes),
          title:title,
          body:
          "Task due in ${duration.inHours>0?
          "${duration.inHours} hour(s)"
              :"${duration.inMinutes} minutes"}",
          scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
          notificationDetails:   const NotificationDetails(
            android:  AndroidNotificationDetails
              ('todo_channel', 'Todo Reminders',
              channelDescription: 'Task reminder notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

        );
      }
    }
  }
  static Future<void> cancelTaskReminders(String taskId) async
  {
    final offsets=[1440,60,10];
    for(final minutes in offsets)
    {
      await _notifications.cancel(
        id:   _generateId(taskId,minutes));
    }
  }
}
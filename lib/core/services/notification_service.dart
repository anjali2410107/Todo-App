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
      const Duration(minutes: 30),
      const Duration(minutes: 0),
    ];
    for(final duration in reminderDurations)
    {
      final reminderTime=dueDate.subtract(duration);
      print("NOW: $now");
      print("Checking reminder: $duration at $reminderTime");
      if(reminderTime.isBefore(now))
        {
          print("Skipping reminder because time already passed");
          continue;
        }
        print("Scheduling notification at $reminderTime");
          await _notifications.zonedSchedule(
          id:_generateId(taskId,duration.inMinutes),
          title:title,
          body: duration.inMinutes == 0
              ? "Task is due now!"
              : "Task due in ${duration.inHours > 0
              ? "${duration.inHours} hour(s)"
              : "${duration.inMinutes} minutes"}",
          scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
          notificationDetails:   const NotificationDetails(
            android:  AndroidNotificationDetails
              ('todo_channel', 'Todo Reminders',
              channelDescription: 'Task reminder notifications',
              importance: Importance.max,
              priority: Priority.high,
              category: AndroidNotificationCategory.reminder,
              visibility: NotificationVisibility.public,
              ticker: 'ticker',),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );}}
  static Future<void> cancelTaskReminders(String taskId) async
  {
    final offsets=[30,0];
    for(final minutes in offsets)
    {
      await _notifications.cancel(
        id:   _generateId(taskId,minutes));
    }}
static Future<void> scheduleStartReminder
    ({
    required String taskId,
  required String title,
  required DateTime startDate,
}) async
{
  final now =DateTime.now();
  if(startDate.isBefore(now))
    {
      return;
    }
  await _notifications.zonedSchedule(
      id: taskId.hashCode+5000,
      title: title,
      body: "Time to start: $title",
      scheduledDate: tz.TZDateTime.from(startDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'start_channel',
            'Task Start Reminders',
        channelDescription: 'Reminder to start a task',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}

}
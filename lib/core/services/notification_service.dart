import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
 class NotificationService{
   static final FlutterLocalNotificationsPlugin _notifications=
       FlutterLocalNotificationsPlugin();

   static Future<void> init() async{
     tz_data.initializeTimeZones();

     const androidSettings=AndroidInitializationSettings(
       '@mipmap/ic_launcher',
     );
     const settings=InitializationSettings(
       android: androidSettings,
     );
      await _notifications.initialize(settings);
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
       const Duration(minutes: 10),
     ];

     for(final duration in reminderDurations)
       {
         final reminderTime=dueDate.subtract(duration);
       }

   }
 }

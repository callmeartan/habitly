import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io' show Platform;
import 'dart:math';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  final List<String> habitReminderMessages = [
    "Don't let the streak break! Time to work on: ",
    "Your future self will thank you! Let's focus on: ",
    "A little progress each day adds up. Start: ",
    "Consistency is key. Ready to tackle: ",
    "Your journey to success continues. Commit to: ",
    "Small habits build big changes. Time for: ",
    "Stay on track! Dedicate some time to: ",
    "Make today count. Start: ",
    "Your daily boost: ",
    "Great habits make great lives. Begin: ",
  ];

  final List<String> taskReminderMessages = [
    "Knock it off your list! '",
    "It's crunch time! Don't forget: '",
    "Stay ahead of your schedule. Complete: '",
    "Be productive today! '",
    "Every task is a step closer to your goals. Start: '",
    "Get it done! You're closer to completing: '",
    "Time to shine! Focus on: '",
    "Tick it off your to-do list: '",
    "Don't delay, get underway! '",
    "Stay sharp and finish strong: '",
  ];

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {},
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {},
    );
  }

  Future<void> scheduleHabitReminder({
    required int id,
    required String habitName,
    DateTime? scheduledTime,
  }) async {
    if (scheduledTime == null) return;

    final message = habitReminderMessages[Random().nextInt(habitReminderMessages.length)];

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Time for your Habit!',
      '$message$habitName.',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_reminders',
          'Habit Reminders',
          channelDescription: 'Notifications for habit reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default.wav',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleTaskReminder({
    required int id,
    required String taskTitle,
    DateTime? scheduledTime,
  }) async {
    if (scheduledTime == null) return;

    try {
      final message = taskReminderMessages[Random().nextInt(taskReminderMessages.length)];
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Task Reminder',
        '$message$taskTitle\'',
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            sound: 'default.wav',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelReminder(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllReminders() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final settings = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings ?? false;
    } else if (Platform.isAndroid) {
      final granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
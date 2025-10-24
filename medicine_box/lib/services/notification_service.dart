import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:medicine_box/services/log_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService notificationService =
      NotificationService._internal();

  final log = LogService().logger;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final String _channelId = 'medication_channel_v8';
  final String _channelName = 'Medication Reminders';
  final String _channelDescription =
      'Canal para relembrar o usuário da medicação';

  Future<void> init() async {
    log.i("[NS] - Inicializando serviço de notificações");
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_pill');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );

    await androidImplementation?.createNotificationChannel(channel);

    final sensor = await Permission.notification.request();
    if (sensor.isGranted) {
      log.i("[NS] - Permissão de notificação concedida");
    } else {
      log.w("[NS] - Permissão de notificação negada");
    }

    await requestExactAlarmPermission();

    // await NotificationService
    //     .notificationService
    //     .flutterLocalNotificationsPlugin
    //     .show(
    //       999,
    //       'Permissões de lembrete liberadas!',
    //       'Canal de comunicação e permissão ok',
    //       NotificationDetails(
    //         android: AndroidNotificationDetails(
    //           _channelId,
    //           _channelName,
    //           channelDescription: _channelDescription,
    //           importance: Importance.max,
    //           priority: Priority.high,
    //           playSound: true,
    //           enableVibration: true,
    //           category: AndroidNotificationCategory.alarm,
    //         ),
    //       ),
    //     );
  }

  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        final androidPlugin = NotificationService
            .notificationService
            .flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        final bool? granted = await androidPlugin
            ?.requestExactAlarmsPermission();

        if (granted != null && granted) {
          log.i('[EXACT ALARM] Permissão concedida ✅');
        } else {
          log.i('[EXACT ALARM] Permissão negada ❌ — abrindo configurações…');
          await openAppSettings(); // Abre direto as configs do app
        }
      } on PlatformException catch (e) {
        log.e('[EXACT ALARM] Exceção: $e');
        await openAppSettings();
      }
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    log.i(
      "[NS] - Agendando notificação (ID: $id) para ${scheduledAt.toIso8601String()}",
    );
    final tz.TZDateTime scheduledTime = tz.TZDateTime.from(
      scheduledAt,
      tz.local,
    );

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      log.i("[NS] - Agendando via zonedSchedule para $scheduledTime");
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      log.i("[NS] - zonedSchedule OK");
    } on PlatformException catch (e) {
      log.w(
        "[NS] - zonedSchedule falhou: ${e.code}. Tentando fallback schedule()",
      );
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      log.i("[NS] - schedule() fallback OK");
    }
  }
}

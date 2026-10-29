import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notifiche di sistema senza server: quelle "ad app chiusa" vengono programmate
/// sul telefono nel momento in cui l'utente esce dall'app (sostituisce OneSignal + Cloudflare
/// della web app per la demo). Per notifiche legate a eventi reali del backend
/// (es. risposta di un operatore) serve comunque un push remoto (FCM / OneSignal).
class Notifs {
  static final FlutterLocalNotificationsPlugin _p = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static void Function(String href)? onOpen;
  static String? launchHref;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'yooppe_main',
      'Messaggi e attività',
      channelDescription: 'Nuovi messaggi, foto private, visite e mi piace',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
  );

  static Future<void> init() async {
    if (_ready || kIsWeb) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _p.initialize(settings, onDidReceiveNotificationResponse: (r) {
      final h = r.payload;
      if (h != null && h.isNotEmpty) onOpen?.call(h);
    });
    final launch = await _p.getNotificationAppLaunchDetails();
    if (launch != null && launch.didNotificationLaunchApp) {
      launchHref = launch.notificationResponse?.payload;
    }
    _ready = true;
  }

  /// Chiede il permesso di sistema. Restituisce true se concesso.
  static Future<bool> request() async {
    if (!_ready) return false;
    if (Platform.isAndroid) {
      final a = _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await a?.requestNotificationsPermission() ?? false;
    }
    if (Platform.isIOS) {
      final i = _p.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await i?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  /// Su Android legge lo stato reale (l'utente può cambiarlo dalle impostazioni). Su iOS null = sconosciuto.
  static Future<bool?> enabled() async {
    if (!_ready) return null;
    if (Platform.isAndroid) {
      final a = _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await a?.areNotificationsEnabled();
    }
    return null;
  }

  static int _id = 100;
  static Future<void> show(String title, String body, String href) async {
    if (!_ready) return;
    _id = _id >= 800 ? 100 : _id + 1;
    await _p.show(_id, title, body, _details, payload: href);
  }

  static Future<void> schedule(int id, Duration after, String title, String body, String href) async {
    if (!_ready) return;
    final when = tz.TZDateTime.now(tz.UTC).add(after);
    await _p.zonedSchedule(
      id,
      title,
      body,
      when,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: href,
    );
  }

  static Future<void> cancel(int id) async {
    if (!_ready) return;
    await _p.cancel(id);
  }
}

import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:relay_app/core/config/api_config.dart';
import 'package:relay_app/core/services/auth_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'high_importance_channel',
    'Zgłoszenia Usterek',
    description: 'Kanał do natychmiastowych powiadomień o usterkach.',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // FIX 1: Dodany argument nazwany "settings:"
    await _localNotifications.initialize(settings: initializationSettings);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? fcmToken = await _fcm.getToken();

      if (fcmToken != null) {
        await _sendTokenToBackend(fcmToken);
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        // FIX 2: Dodany argument nazwany "notificationDetails:"
        _localNotifications.show(
          id: notification.hashCode, // DODANE: id:
          title: notification.title, // DODANE: title:
          body: notification.body, // DODANE: body:
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: android.smallIcon,
            ),
          ),
        );
      }
    });
  }

  Future<void> _sendTokenToBackend(String token) async {
    final authToken = await AuthService().getToken();
    if (authToken == null) return;

    final url = Uri.parse('${ApiConfig.baseUrl}/user/fcm-token');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('Sukces: Token FCM zapisany na backendzie.');
      } else {
        debugPrint('Błąd zapisu tokenu FCM: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Błąd połączenia podczas wysyłania tokenu FCM: $e');
    }
  }
}

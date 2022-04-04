import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

String? currentDeviceMsgToken;

abstract class NotificationBase {
  Future initialize();

  Future sendNotification({required Map<String, dynamic> param});
}

class FirebaseNotification implements NotificationBase {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  late AndroidNotificationChannel channel;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  final dio = Dio(BaseOptions()
    ..contentType = Headers.jsonContentType
    ..headers = {
      'Authorization':
          'key=AAAAmRZnX6E:APA91bEPKSrnv2it1tGShlIwtqPRYkDOar5f2U-MuDpjJC_SD2nf-cr51Zpw2q6lMiy1oU7WrYna8p1Cc8fqFR80ZooVG_YZUjiPQYuDKA6HLXIqba_hRnFYDon1JuUZazzJwy1yXWjY'
    });

  @override
  Future initialize() async {
    _firebaseMessaging.getToken().then(
      (value) {
        return currentDeviceMsgToken = value ?? "";
      },
    );

    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (!kIsWeb) {
      channel = const AndroidNotificationChannel(
        '02862582324', // id
        'High Importance Notifications', // title
        description:
            'This channel is used for important notifications.', // description
        importance: Importance.high,
      );

      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessage.listen((message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null && !kIsWeb) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: 'mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      log(message.data.toString());
    });
  }

  @override
  Future sendNotification({required Map<String, dynamic> param}) async {
    await dio.post('https://fcm.googleapis.com/fcm/send', data: param);
  }
}

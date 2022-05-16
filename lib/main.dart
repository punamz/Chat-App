import 'dart:async';

import 'package:chat_app/constants/app_theme.dart';
import 'package:chat_app/constants/strings.dart';
import 'package:chat_app/pages/landing_page.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/notification.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

RemoteMessage? initMsg;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    initMsg = await FirebaseMessaging.instance.getInitialMessage();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    runApp(MyApp());
  },
      (error, stack) =>
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final NotificationBase notification = FirebaseNotification()..initialize();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthBase>(create: (_) => Auth()),
        Provider<NotificationBase>(create: (_) => notification),
      ],
      child: MaterialApp(
        title: Strings.appName,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const LandingPage(),
      ),
    );
  }
}

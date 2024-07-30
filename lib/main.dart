// ignore_for_file: avoid_print

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:toastification/toastification.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/authentication/screen/auth_screen.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/firebase_options.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/theme/pallette.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Constants.deviceToken = await FirebaseMessaging.instance.getToken();
  runApp(
    const ProviderScope(
      child: ToastificationWrapper(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends ConsumerState<MyApp> {
  UserModel? userData;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void _getUserData(WidgetRef ref, User data) async {
    userData = await ref
        .watch(authControllerProvider.notifier)
        .getUserData(data.uid)
        .first;
    ref.read(userProvider.notifier).update((state) => userData);
  }

  void _setupLocalNotifications() async {
    final Completer<bool> completer = Completer();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        _handleNotificationTap(response, completer);
      },
    );
  }

  Future<void> _handleNotificationTap(
      NotificationResponse response, Completer<bool> completer) async {
    if (response.payload != null) {
      if (response.payload == 'answer_action') {
        print('User tapped on answer action');
        completer.complete(true);
      } else if (response.payload == 'decline_action') {
        print('User tapped on decline action');
        completer.complete(false);
      }
    }
  }

  Future<bool> showIncomingCall(RemoteMessage message) async {
    Completer<bool> completer = Completer<bool>();

    const String channelId = 'incoming_call_channel';
    const String channelName = 'Incoming Calls';
    const String channelDescription = 'Channel for incoming call notifications';

    const AndroidNotificationAction answerAction = AndroidNotificationAction(
      'answer_action',
      'Answer',
      icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const AndroidNotificationAction declineAction = AndroidNotificationAction(
      'decline_action',
      'Decline',
      icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      actions: <AndroidNotificationAction>[answerAction, declineAction],
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: 'incoming_call',
    );

    // Lắng nghe hành động từ thông báo
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationTap(response, completer);
      },
    );

    return completer.future;
  }

  @override
  void initState() {
    super.initState();
    _setupLocalNotifications();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
          showIncomingCall(message);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(authStageChangeProvider).when(
          data: (user) {
            if (user != null) {
              _getUserData(ref, user);
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Hash Balance',
                theme: Pallete.darkModeAppTheme,
                home: Consumer(
                  builder: (context, watch, child) {
                    final userData = ref.watch(userProvider);
                    if (userData != null) {
                      return PopScope(
                        onPopInvoked: (didPop) {
                          final authController =
                              ref.watch(authControllerProvider.notifier);
                          authController.signOut(ref);
                        },
                        child: const HomeScreen(),
                      );
                    } else {
                      return const Loading();
                    }
                  },
                ),
              );
            } else {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Hash Balance',
                theme: Pallete.darkModeAppTheme,
                home: const AuthScreen(),
              );
            }
          },
          error: (error, stackTrace) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Hash Balance',
            home: ErrorText(error: error.toString()),
          ),
          loading: () => const MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Hash Balance',
            home: Loading(),
          ),
        );
  }
}

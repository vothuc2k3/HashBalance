// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:toastification/toastification.dart';

import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/authentication/screen/auth_screen.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/firebase_options.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/theme/pallette.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  void _getUserData(WidgetRef ref, User data) async {
    userData = await ref
        .watch(authControllerProvider.notifier)
        .getUserData(data.uid)
        .first;
    ref.read(userProvider.notifier).update((state) => userData);
  }

  void _setupLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        _handleNotificationTap(response);
      },
    );
  }

  Future<void> _handleNotificationTap(NotificationResponse response) async {
    print(response); // In ra chi tiết của NotificationResponse để kiểm tra
    if (response.payload != null) {
      try {
        // Decode the payload to a Map
        final payloadData = jsonDecode(response.payload!);
        print(
            'Payload data: $payloadData'); // In ra chi tiết của payload để kiểm tra

        // Check the type and navigate accordingly
        if (payloadData['type'] == 'accept_request') {
          // Navigate to the corresponding screen
          final targetUser = await _fetchUserByUid(payloadData['uid']);
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => OtherUserProfileScreen(
                targetUser: targetUser,
              ),
            ),
          );
        } else if (payloadData['type'] == 'friend_request') {
          // Navigate to the corresponding screen
          final targetUser = await _fetchUserByUid(payloadData['uid']);
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => OtherUserProfileScreen(
                targetUser: targetUser,
              ),
            ),
          );
        } else {
          print('Unknown action');
        }
      } catch (e) {
        print('Error parsing payload: $e');
      }
    } else {
      print('No payload found');
    }
  }

  Future<UserModel> _fetchUserByUid(String uid) async {
    return ref
        .watch(userControllerProvider.notifier)
        .fetchUserByUidProvider(uid);
  }

  Future<void> showLocalNotification(RemoteMessage message) async {
    const String channelId = 'default_channel';
    const String channelName = 'Default';
    const String channelDescription = 'Default Channel for Notifications';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Tạo payload từ message data
    final Map<String, dynamic> payloadData = message.data;

    final payload = jsonEncode(payloadData); // Đảm bảo payload là JSON hợp lệ

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  void _updateUserData() async {
    _users.doc(userData!.uid).snapshots().listen((event) {
      if (event.exists) {
        final data = event.data() as Map<String, dynamic>;

        final createdAt = data['createdAt'] as Timestamp;
        final hashAge = DateTime.now().difference(createdAt.toDate()).inDays;

        _users.doc(userData!.uid).update({
          'hashAge': hashAge,
        });
      }
    });
  }

  @override
  void initState() {
    _setupLocalNotifications();
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;
        if (notification != null && android != null) {
          showLocalNotification(message);
        }
      },
    );
    if (userData != null) {
      _updateUserData();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(authStageChangeProvider).when(
          data: (user) {
            if (user != null) {
              _getUserData(ref, user);
              return MaterialApp(
                navigatorKey: navigatorKey,
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
                navigatorKey: navigatorKey,
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

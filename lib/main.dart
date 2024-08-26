// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/hive_models/community/hive_community_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:toastification/toastification.dart';

import 'package:hash_balance/core/hive_models/user_model/hive_user_model.dart';
import 'package:hash_balance/core/services/joined_communities_service.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/authentication/screen/auth_screen.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/features/message/screen/message_screen.dart';
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
  await FirebaseMessaging.instance.getToken();
  await Hive.initFlutter();
  Hive.registerAdapter(HiveUserModelAdapter());
  Hive.registerAdapter(HiveCommunityModelAdapter());
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
  late final JoinedCommunitiesService _joinedCommunitiesService;

  void _getUserData(User data) async {
    userData = await ref
        .watch(authControllerProvider.notifier)
        .getUserData(data.uid)
        .first;
    ref.watch(userProvider.notifier).update((state) => userData);
  }

  void _setupLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        await _handleNotificationTap(response);
      },
    );
  }

  Future<void> _handleNotificationTap(NotificationResponse response) async {
    if (response.payload != null) {
      try {
        final payloadData = jsonDecode(response.payload!);

        switch (payloadData['type']) {
          case 'accept_request':
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const SplashScreen(),
              ),
            );

            final targetUser = await _fetchUserByUid(payloadData['uid']);
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (context) => OtherUserProfileScreen(
                  targetUser: targetUser,
                ),
              ),
            );
            break;

          case 'friend_request':
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const SplashScreen(),
              ),
            );
            final targetUser = await _fetchUserByUid(payloadData['uid']);

            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (context) => OtherUserProfileScreen(
                  targetUser: targetUser,
                ),
              ),
            );
            break;
          case 'incoming_message':
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const SplashScreen(),
              ),
            );
            final targetUser = await _fetchUserByUid(payloadData['uid']);

            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (context) => MessageScreen(
                  targetUser: targetUser,
                ),
              ),
            );
            break;
          default:
            print('Unknown action');
            break;
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

    final Map<String, dynamic> payloadData = message.data;

    final payload = jsonEncode(payloadData);

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: payload,
    );
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
    _joinedCommunitiesService = JoinedCommunitiesService();
    _joinedCommunitiesService.fetchJoinedCommunities(userData);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userProvider);

    return ref.watch(authStageChangeProvider).when(
          data: (user) {
            if (user != null) {
              _getUserData(user);
              return MaterialApp(
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                title: 'Hash Balance',
                theme: Pallete.darkModeAppTheme,
                home: userData != null ? const HomeScreen() : const Loading(),
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

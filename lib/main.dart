import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/services/community_service.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/call/controller/call_controller.dart';
import 'package:hash_balance/features/call/screen/incoming_call_screen.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/network/controller/network_controller.dart';
import 'package:hash_balance/models/call_model.dart';
import 'package:hash_balance/models/conbined_models/call_data_model.dart';
import 'package:logger/logger.dart';
import 'package:multi_trigger_autocomplete/multi_trigger_autocomplete.dart';
import 'package:toastification/toastification.dart';

import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/services/device_token_service.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/authentication/screen/auth_screen.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/features/message/screen/private_message_screen.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:hash_balance/firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://d6ba9f416ada27f226f00ff8d11700eb@o4507910984040448.ingest.de.sentry.io/4507910985875536';
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
    },
    appRunner: () {
      runApp(
        const ProviderScope(
          child: ToastificationWrapper(
            child: MyApp(),
          ),
        ),
      );
    },
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
  late final DeviceTokenService _deviceTokenService;
  late final CommunityService _communityService;

  ConnectivityResult? lastStatus;

  void _getUserData(User? data) async {
    if (data != null) {
      final userData = await ref
          .watch(authControllerProvider.notifier)
          .getUserData(data.uid)
          .first;
      ref.read(userProvider.notifier).update((state) => userData);
      _deviceTokenService.updateUserDeviceToken(userData);
      await _communityService.getUserJoinedCommunities(userData.uid);
    } else {
      ref.read(userProvider.notifier).update((state) => null);
    }
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
          case Constants.acceptRequestType:
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const SplashScreen(),
              ),
            );

            final targetUser = await _fetchUserByUid(payloadData['uid']);
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    OtherUserProfileScreen(targetUid: targetUser.uid),
              ),
            );
            break;

          case Constants.friendRequestType:
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const SplashScreen(),
              ),
            );
            final targetUser = await _fetchUserByUid(payloadData['uid']);

            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    OtherUserProfileScreen(targetUid: targetUser.uid),
              ),
            );
            break;
          case Constants.incomingMessageType:
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const SplashScreen(),
              ),
            );
            
            final targetUser = await _fetchUserByUid(payloadData['uid']);

            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (context) => PrivateMessageScreen(
                  targetUser: targetUser,
                ),
              ),
            );
            break;
          case Constants.moderatorInvitationType:
            final communityId = payloadData['communityId'];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SplashScreen(),
              ),
            );
            final currentUser = ref.read(userProvider)!;
            final result = await ref
                .watch(moderationControllerProvider.notifier)
                .fetchMembershipStatus(
                  getMembershipId(
                      uid: currentUser.uid, communityId: communityId),
                );

            result.fold(
              (l) {
                showToast(false, 'Unexpected error happened...');
                Navigator.pop(context);
              },
              (r) async {
                final community = await ref
                    .read(communityControllerProvider.notifier)
                    .fetchCommunityById(communityId);
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommunityScreen(
                        communityId: community.id,
                      ),
                    ),
                  );
                }
              },
            );
            break;
          case Constants.newFollowerType:
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const SplashScreen(),
              ),
            );
            final targetUser = await _fetchUserByUid(payloadData['uid']);
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (context) =>
                    OtherUserProfileScreen(targetUid: targetUser.uid),
              ),
            );
            break;
          case Constants.incomingCallType:
            final caller = await _fetchUserByUid(payloadData['callerUid']);
            final call = await _fetchCallById(payloadData['callId']);
            final callData = CallDataModel(
              call: call!,
              caller: caller,
              receiver: ref.read(userProvider)!,
            );
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => IncomingCallScreen(
                  callData: callData,
                ),
              ),
            );
            break;
          default:
            break;
        }
      } catch (e) {
        Logger().e('Error parsing payload: $e');
      }
    } else {
      Logger().e('No payload found');
    }
  }

  Future<UserModel> _fetchUserByUid(String uid) {
    return ref
        .watch(userControllerProvider.notifier)
        .fetchUserByUidProvider(uid);
  }

  Future<Call?> _fetchCallById(String callId) {
    final call =
        ref.watch(callControllerProvider.notifier).listenToCall(callId).first;
    return call;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
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

  String _connectivityStatusMessage(ConnectivityResult status) {
    switch (status) {
      case ConnectivityResult.wifi:
        return 'Connected to Wi-Fi';
      case ConnectivityResult.mobile:
        return 'Connected to Mobile Network';
      case ConnectivityResult.none:
        return 'No Network Connection';
      default:
        return 'Unknown Network Status';
    }
  }

  @override
  void initState() {
    super.initState();
    _setupLocalNotifications();
    FirebaseMessaging.onMessage.listen(
      (message) {
        final notification = message.notification;
        final android = message.notification?.android;
        if (notification != null && android != null) {
          _showLocalNotification(message);
        }
      },
    );

    _deviceTokenService = DeviceTokenService();
    _communityService = CommunityService();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<ConnectivityResult>>>(connectivityProvider,
        (previous, next) {
      next.when(
        data: (statuses) {
          if (statuses.isNotEmpty) {
            final lastConnectivity = statuses.last;
            if (lastConnectivity != lastStatus) {
              lastStatus = lastConnectivity;
              showToast(true, _connectivityStatusMessage(lastConnectivity));
            }
          }
        },
        loading: () {},
        error: (error, stack) {
          showToast(false, error.toString());
        },
      );
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _getUserData(user);
      return Portal(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Hash Balance',
          theme: Pallete.darkModeAppTheme,
          home: ref.watch(userProvider) != null
              ? const HomeScreen()
              : const SplashScreen(),
        ),
      );
    } else {
      return Portal(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Hash Balance',
          theme: Pallete.darkModeAppTheme,
          home: const AuthScreen(),
        ),
      );
    }
  }
}

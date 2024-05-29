import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/user_profile/screen/edit_profile/edit_user_profile.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:routemaster/routemaster.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/core/common/unknown_route.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/authentication/screen/auth_screen.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_in_screen.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_up_screen.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/community/screen/create_community_screen.dart';
import 'package:hash_balance/features/community/screen/mod_tools/edit_community_screen.dart';
import 'package:hash_balance/features/community/screen/mod_tools/mod_tools_screen.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/features/setting/setting_screen.dart';
import 'package:hash_balance/features/user_profile/screen/current_user_profile_screen.dart';
import 'package:hash_balance/firebase_options.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/theme/pallette.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
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
  final _loggedOutRoute = RouteMap(
    routes: {
      '/': (_) => const MaterialPage(
            child: AuthScreen(),
          ),
      '/email-sign-up': (_) => const MaterialPage(
            child: EmailSignUpScreen(),
          ),
      '/email-sign-in': (_) => const MaterialPage(
            child: EmailSignInScreen(),
          ),
    },
    onUnknownRoute: (_) => const MaterialPage(
      child: UnknownRouteScreen(),
    ),
  );

  final _loggedInRoute = RouteMap(
    routes: {
      '/': (_) => const MaterialPage(
            child: HomeScreen(),
          ),
      '/create-community': (_) => const MaterialPage(
            child: CreateCommunityScreen(),
          ),
      '/#=/:name': (route) => MaterialPage(
            child: CommunityScreen(name: route.pathParameters['name']!),
          ),
      '/mod-tools/:name': (route) => MaterialPage(
            child: ModToolsScreen(name: route.pathParameters['name']!),
          ),
      '/edit_community/:name': (route) => MaterialPage(
            child: EditCommunityScreen(name: route.pathParameters['name']!),
          ),
      '/setting': (_) => const MaterialPage(
            child: SettingScreen(),
          ),
      '/user-profile/:uid': (route) => MaterialPage(
            child: CurrentUserProfileScreen(uid: route.pathParameters['uid']!),
          ),
      '/user-profile/view/:uid': (route) => MaterialPage(
            child: OtherUserProfileScreen(uid: route.pathParameters['uid']!),
          ),
      '/user-profile/edit/:uid': (route) => MaterialPage(
            child: EditUserProfileScreen(uid: route.pathParameters['uid']!),
          ),
    },
    onUnknownRoute: (_) => const MaterialPage(
      child: UnknownRouteScreen(),
    ),
  );

  UserModel? userData;

  void _getUserData(WidgetRef ref, User data) async {
    userData = await ref
        .watch(authControllerProvider.notifier)
        .getUserData(data.uid)
        .first;
    ref.read(userProvider.notifier).update((state) => userData);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(authStageChangeProvider).when(
          data: (user) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Hash Balance',
            theme: Pallete.darkModeAppTheme,
            routerDelegate: RoutemasterDelegate(
              routesBuilder: (_) {
                if (user != null) {
                  _getUserData(ref, user);
                  if (userData != null) {
                    return _loggedInRoute;
                  }
                }
                return _loggedOutRoute;
              },
            ),
            routeInformationParser: const RoutemasterParser(),
          ),
          error: (error, stackTrace) => ErrorText(error: error.toString()),
          loading: () => const Loading(),
        );
  }
}

import 'package:flutter/material.dart';
import 'package:hash_balance/core/common/unknown_route.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_in_screen.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_up_screen.dart';
import 'package:hash_balance/features/community/screen/mod_tools/edit_community_visual_screen.dart';
import 'package:hash_balance/features/community/screen/mod_tools/mod_tools_screen.dart';
import 'package:hash_balance/features/authentication/screen/auth_screen.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/community/screen/create_community_screen.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/features/setting/setting_screen.dart';
import 'package:routemaster/routemaster.dart';

final loggedOutRoute = RouteMap(
  routes: {
    '/': (_) => const MaterialPage(
          child: SignInScreen(),
        ),
    '/email-sign-in': (_) => const MaterialPage(
          child: EmailSignInScreen(),
        ),
    '/email-sign-up': (_) => const MaterialPage(
          child: EmailSignUpScreen(),
        ),
  },
  onUnknownRoute: (_) => const MaterialPage(
    child: UnknownRouteScreen(),
  ),
);
final loggedInRoute = RouteMap(
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
          child: EditCommunityVisualScreen(name: route.pathParameters['name']!),
        ),
    '/setting': (_) => const MaterialPage(
          child: SettingScreen(),
        ),
  },
  onUnknownRoute: (_) => const MaterialPage(
    child: UnknownRouteScreen(),
  ),
);

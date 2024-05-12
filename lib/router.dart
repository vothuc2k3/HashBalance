import 'package:flutter/material.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_in_screen.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_up_screen.dart';
import 'package:hash_balance/features/authentication/screen/mod_tools/edit_community_screen.dart';
import 'package:hash_balance/features/authentication/screen/mod_tools/mod_tools_screen.dart';
import 'package:hash_balance/features/authentication/screen/sign_in_screen.dart';
import 'package:hash_balance/features/gaming_community/screen/community_screen.dart';
import 'package:hash_balance/features/gaming_community/screen/create_community_screen.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:routemaster/routemaster.dart';

final loggedOutRoute = RouteMap(routes: {
  '/': (_) => const MaterialPage(
        child: SignInScreen(),
      ),
  '/email-sign-in': (_) => MaterialPage(
        child: EmailSignInScreen(),
      ),
  '/email-sign-up': (_) => MaterialPage(
        child: EmailSignUpScreen(),
      ),
});
final loggedInRoute = RouteMap(routes: {
  '/': (_) => const MaterialPage(
        child: HomeScreen(),
      ),
  '/create-community': (_) => const MaterialPage(
        child: CreateGamingCommunityScreen(),
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
});

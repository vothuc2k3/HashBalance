//logged out routes
//logged in routes

import 'package:flutter/material.dart';
import 'package:hash_balance/features/authentication/screen/sign_in_screen.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:routemaster/routemaster.dart';

final loggedOutRoute = RouteMap(routes: {
  '/': (_) => const MaterialPage(
        child: SignInScreen(),
      )
});
final loggedInRoute = RouteMap(routes: {
  '/': (_) => const MaterialPage(
        child: HomeScreen(),
      )
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:routemaster/routemaster.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  void signOut(BuildContext context, WidgetRef ref) {
    ref.read(authControllerProvider.notifier).signOut();
    Routemaster.of(context).replace('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Setting',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Pallete.redColor,
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => signOut(context, ref),
          ),
        ],
      ),
    );
  }
}

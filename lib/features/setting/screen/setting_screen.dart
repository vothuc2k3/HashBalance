import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/screen/auth_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/theme/pallette.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<SettingScreen> createState() {
    return SettingScreenState();
  }
}

class SettingScreenState extends ConsumerState<SettingScreen> {
  void _signOut(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
    await ref.watch(authControllerProvider.notifier).signOut(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),
      (route) => false,
    );
  }

  void _testButton() async {}

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: const Text(
          'Setting',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
        ),
        child: Column(
          children: [
            ListTile(
              leading: isLoading
                  ? const Loading()
                  : Icon(
                      Icons.logout,
                      color: Pallete.redColor,
                    ),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => _signOut(context),
            ),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Pallete.redColor,
              ),
              title: const Text(
                'TEST BUTTON',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _testButton,
            ),
          ],
        ),
      ),
    );
  }
}

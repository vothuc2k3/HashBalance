import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';

class GoogleSignInButton extends ConsumerWidget {
  final BuildContext parentContext;

  const GoogleSignInButton({
    required this.parentContext,
    super.key,
  });

  void signInWithGoogle(WidgetRef ref) async {
    final result =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    result.fold((l) {
      showToast(false, l.message);
    }, (r) {
      Navigator.of(parentContext).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => signInWithGoogle(ref),
      icon: Image.asset(
        Constants.googleLogoPath,
        width: 35,
      ),
      label: const Text(
        'Join with Google',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF592044),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

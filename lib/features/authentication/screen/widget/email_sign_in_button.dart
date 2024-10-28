import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_up_screen.dart';

class EmailSignInButton extends ConsumerWidget {
  const EmailSignInButton({
    super.key,
  });

  void _navigateToEmailSignUpScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailSignUpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _navigateToEmailSignUpScreen(context),
      icon: Image.asset(
        Constants.emailLogoPath,
        width: 35,
      ),
      label: const Text(
        'Join with Email',
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

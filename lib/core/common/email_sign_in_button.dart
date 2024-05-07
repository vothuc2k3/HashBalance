import 'package:flutter/material.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:routemaster/routemaster.dart';

class EmailSignInButton extends StatelessWidget {
  const EmailSignInButton({super.key});

  void navigateToEmailSignInScreen(BuildContext context) {
    Routemaster.of(context).push('/email-sign-in');
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        navigateToEmailSignInScreen(context);
      },
      icon: Image.asset(
        Constants.emailLogoPath,
        width: 35,
      ),
      label: const Text(
        'Sign in with Email',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Pallete.greyColor,
        minimumSize: const Size(
          double.infinity,
          50,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

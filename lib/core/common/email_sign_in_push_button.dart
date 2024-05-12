import 'package:flutter/material.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:routemaster/routemaster.dart';

class EmailSignUpPushButton extends StatelessWidget {
  const EmailSignUpPushButton({super.key});

  void navigateToEmailSignUpScreen(BuildContext context) {
    Routemaster.of(context).push('/email-sign-up');
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        navigateToEmailSignUpScreen(context);
      },
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

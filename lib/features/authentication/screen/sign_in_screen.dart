import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/email_sign_in_push_button.dart';
import 'package:hash_balance/core/common/google_sign_in_button.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          Constants.logoPath,
          height: 45,
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Skip',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const LoadingCircular()
          : Column(
              children: [
                const SizedBox(height: 30),
                const Text(
                  'Let\'s join the communities!',
                  style: TextStyle(
                    fontSize: 24,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    Constants.signinEmotePath,
                    height: 400,
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(
                    right: 30,
                    left: 30,
                  ),
                  child: GoogleSignInButton(),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.only(
                    right: 30,
                    left: 30,
                  ),
                  child: EmailSignInPushButton(),
                ),
              ],
            ),
    );
  }
}

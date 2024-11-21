import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_up_screen.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_in_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late TextEditingController _emailController;

  void sendResetLink() async {
    final result = await ref
        .watch(authControllerProvider.notifier)
        .sendResetPasswordLink(_emailController.text.trim().toLowerCase());
    result.fold(
      (l) {
        showToast(false, l.message);
      },
      (_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: ref.watch(preferredThemeProvider).first,
              title: const Text('Success'),
              content: const Text(
                  'If your email matches the email you entered, you will receive the reset password link!'),
              actions: [
                TextButton(
                  child: const Text(
                    'Open Gmail',
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                  onPressed: () async {
                    const intent = AndroidIntent(
                      action: 'android.intent.action.VIEW',
                      package: 'com.google.android.gm',
                    );
                    await intent.launch().catchError((e) {
                      showToast(false, 'Gmail app not found!');
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void navigateToSignUpScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailSignUpScreen(),
      ),
    );
  }

  void navigateToSignInScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailSignInScreen(),
      ),
    );
  }

  @override
  void initState() {
    _emailController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
        backgroundColor: const Color(0xFF8c336b),
      ),
      body: isLoading
          ? const Loading()
          : Container(
              width: double.infinity,
              height: screenHeight,
              decoration: const BoxDecoration(
                color: Color(0xFF8c336b),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.1),
                    const Text(
                      'Forgot Your Password?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your email address below to reset your password.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    _buildEmailTextField(),
                    const SizedBox(height: 20),
                    _buildSendEmailButton(),
                    SizedBox(height: screenHeight * 0.03),
                    _buildSignUpSection(),
                    const Divider(
                      color: Colors.white70,
                      thickness: 0.8,
                    ),
                    const SizedBox(height: 10),
                    _buildSignInButton(),
                    SizedBox(height: screenHeight * 0.03),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmailTextField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.email, color: Colors.white70),
        hintText: 'Enter your email',
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildSendEmailButton() {
    return ElevatedButton(
      onPressed: sendResetLink,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF592044),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.send, color: Colors.white),
          SizedBox(width: 10),
          Text(
            'Send Reset Link',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpSection() {
    return Column(
      children: [
        const Text(
          'Don’t have an account?',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () {
            navigateToSignUpScreen(context);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return OutlinedButton(
      onPressed: navigateToSignInScreen,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
      ),
      child: const Text(
        'Back to Login',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

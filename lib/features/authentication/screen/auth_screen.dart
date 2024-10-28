import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/screen/widget/email_sign_in_button.dart';
import 'package:hash_balance/features/authentication/screen/widget/google_sign_in_button.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_in_screen.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_up_screen.dart';
import 'package:hash_balance/features/authentication/screen/forgot_password_screen.dart';
import 'package:rive/rive.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  void navigateToEmailSignUpScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailSignUpScreen(),
      ),
    );
  }

  void navigateToEmailSignInScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailSignInScreen(),
      ),
    );
  }

  void navigateToForgotPasswordScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authControllerProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF8c336b),
        ),
        height: screenHeight,
        child: isLoading
            ? const Loading()
            : SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(height: screenHeight * 0.1),
                        const Text(
                          'Let\'s join the communities!',
                          style: TextStyle(
                            fontSize: 24,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        SizedBox(
                          width: screenWidth * 0.6,
                          height: screenHeight * 0.3,
                          child: const RiveAnimation.asset(
                            fit: BoxFit.fitHeight,
                            'assets/images/Login_character/character.riv',
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.1),
                          child: const GoogleSignInButton(),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.1),
                          child: const EmailSignInButton(),
                        ),
                        const Spacer(),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding:
                                EdgeInsets.only(bottom: screenHeight * 0.05),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Already have an account? ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        navigateToEmailSignInScreen(context);
                                      },
                                      child: const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 2.0,
                                              color: Colors.black45,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

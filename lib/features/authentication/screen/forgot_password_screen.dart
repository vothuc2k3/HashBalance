import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/common/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_up_screen.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_in_screen.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:url_launcher/url_launcher.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late TextEditingController _emailController;
  bool? isEmailExists = true;

  void sendResetLink() async {
    final result = await ref
        .watch(authControllerProvider.notifier)
        .sendResetPasswordLink(_emailController.text.trim().toLowerCase());
    result.fold(
      (l) {
        showToast(false, l.toString());
      },
      (_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text(
                  'If your email matches the email you entered, you will the reset password link!'),
              actions: [
                TextButton(
                  child: const Text('Open to Gmail'),
                  onPressed: () async {
                    String gmailUrl = "com.google.android.gm";
                    if (await canLaunchUrl(Uri.parse(gmailUrl))) {
                      await launchUrl(Uri.parse(gmailUrl)); 
                    } else {
                      throw 'Could not launch Gmail';
                    }
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailSignUpScreen(),
      ),
    );
  }

  void navigateToSignInScreen() {
    Navigator.push(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
        backgroundColor: Pallete.greyColor,
      ),
      body: isLoading
          ? const Loading()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Type in your email!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.email, color: Pallete.greyColor),
                      labelText: 'Email Address',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(color: Pallete.greyColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(color: Pallete.greyColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(color: Pallete.greyColor),
                      ),
                      filled: true,
                      fillColor: Pallete.greyColor.withOpacity(0.1),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      sendResetLink();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Pallete.greyColor,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Send Email',
                            style: TextStyle(color: Colors.white)),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Don't Have An Account?",
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {
                      navigateToSignUpScreen(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Pallete.greyColor,
                      side: const BorderSide(color: Pallete.greyColor),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Signup', style: TextStyle(color: Colors.white)),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(
                    thickness: 1,
                    indent: 10,
                    endIndent: 10,
                    color: Pallete.greyColor,
                  ),
                  const Text(
                    'OR',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(
                    thickness: 1,
                    indent: 10,
                    endIndent: 10,
                    color: Pallete.greyColor,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {
                      navigateToSignInScreen();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Pallete.greyColor,
                      side: const BorderSide(color: Pallete.greyColor),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Login', style: TextStyle(color: Colors.white)),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      backgroundColor: Pallete.blackColor,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/auth_text_field.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:routemaster/routemaster.dart';

class EmailSignInScreen extends ConsumerStatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  EmailSignInScreenState createState() {
    return EmailSignInScreenState();
  }
}

class EmailSignInScreenState extends ConsumerState<EmailSignInScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPressed = false;

  void signInWithEmail(BuildContext context, WidgetRef ref) async {
    FocusScope.of(context).unfocus();
    setState(() {
      isPressed = true;
    });
    final result = await ref
        .read(authControllerProvider.notifier)
        .signInWithEmailAndPassword(
          emailController.text.toLowerCase().trim(),
          passwordController.text,
        );
    result.fold((l) {
      if (context.mounted) {
        showSnackBar(context, l.message);
      }
      setState(() {
        isPressed = false;
      });
    }, (r) => Routemaster.of(context).replace('/'));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Scaffold(
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
          body: Column(
            children: [
              const SizedBox(
                height: 30,
              ),
              const Text(
                'Hi our old friend, let\'s sign you back in!',
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 40),

              //email input field
              Padding(
                padding: const EdgeInsets.only(
                  right: 30,
                  left: 30,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Pallete.greyColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AuthTextField(
                    controller: emailController,
                    obscureText: false,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              //password input field
              Padding(
                padding: const EdgeInsets.only(
                  right: 30,
                  left: 30,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Pallete.greyColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AuthTextField(
                    controller: passwordController,
                    obscureText: true,
                    hintText: 'Password',
                    keyboardType: TextInputType.visiblePassword,
                    autofocus: false,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              //submit sign up request button
              Padding(
                padding: const EdgeInsets.only(
                  right: 30,
                  left: 30,
                ),
                child: ElevatedButton(
                  onPressed: isPressed
                      ? () {}
                      : () {
                          signInWithEmail(context, ref);
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Pallete.blueColor,
                  ),
                  child: isPressed
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Let\'s Go',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

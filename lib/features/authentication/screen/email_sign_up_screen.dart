import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/auth_text_field.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:routemaster/routemaster.dart';

class EmailSignUpScreen extends ConsumerWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  EmailSignUpScreen({super.key});

  void signUpWithEmailAndPassword(BuildContext context, WidgetRef ref) async {
    final user = await ref
        .read(authControllerProvider.notifier)
        .signUpWithEmailAndPassword(
          context,
          emailController.text.toLowerCase().trim(),
          passwordController.text,
          nameController.text,
        );
    user.fold(
      (error) {
        showSnackBar(context, error.message);
      },
      (_) {
        Routemaster.of(context).replace('/');
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authControllerProvider);

    return Scaffold(
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
        body: isLoading
            ? const LoadingCircular()
            : Column(
                children: [
                  const SizedBox(
                    height: 30,
                  ),
                  const Text(
                    'Hi new friend, let\'s create your account!',
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

                  //name input field
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
                        controller: nameController,
                        obscureText: false,
                        hintText: 'User name',
                        keyboardType: TextInputType.name,
                        autofocus: false,
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
                      onPressed: () {
                        signUpWithEmailAndPassword(context, ref);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: Pallete.blueColor,
                      ),
                      child: const Text(
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
    );
  }
}

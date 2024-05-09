import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/auth_text_field.dart';
import 'package:hash_balance/core/common/constants/constants.dart';

class EmailSignInScreen extends ConsumerWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  EmailSignInScreen({
    super.key,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: Column(
        children: [
          const SizedBox(
            height: 30,
          ),
          const Text(
            'Hi our new friend, let\'s create your account!',
            style: TextStyle(
              fontSize: 24,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.only(
              right: 30,
              left: 30,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF232e37),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AuthTextField(
                controller: emailController,
                obscureText: true,
                hintText: 'Email',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(
              right: 30,
              left: 30,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF232e37),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AuthTextField(
                controller: passwordController,
                obscureText: true,
                hintText: 'Password',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hash_balance/core/common/constants/constants.dart';

class EmailSignInScreen extends StatelessWidget {
  const EmailSignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.arrow_back),
            ),
            Image.asset(Constants.logoPath),
            TextButton(
              onPressed: () {},
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          const Text(
            'Hi there, welcome to Hash Balance',
            style: TextStyle(
              fontSize: 24,
              letterSpacing: 0.5,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty ||
                    !value.contains('@') ||
                    !value.contains('.')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              onSaved: (value) {},
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              validator: (value) {
                if (value == null || value.trim().length < 6) {
                  return 'Password must be at least 6 characters long.';
                }
                return null;
              },
              onSaved: (value) {},
            ),
          ),
        ],
      ),
    );
  }
}

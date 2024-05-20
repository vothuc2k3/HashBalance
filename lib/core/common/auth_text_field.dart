import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final String hintText;
  final TextInputType keyboardType;
  final bool autofocus;
  const AuthTextField({
    super.key,
    required this.controller,
    required this.obscureText,
    required this.hintText,
    required this.keyboardType,
    required this.autofocus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
        ),
        keyboardType: keyboardType,
        autofocus: autofocus,
      ),
    );
  }
}

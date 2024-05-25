import 'dart:async';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:crypt/crypt.dart';
import 'dart:convert';

void showSnackBar(BuildContext context, String text) {
  if (context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
        ),
      );
  }
}

void showMaterialBanner(BuildContext context, String text) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(text),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              }
            },
            child: const Text('DISMISS'),
          ),
        ],
      ),
    );
  }
}

String generateCommunityId() {
  DateTime now = DateTime.now();
  String communityId =
      "${now.year}${now.month}${now.day}${now.hour}${now.minute}${now.second}${now.millisecond}";
  return communityId;
}

String generateRandomString() {
  DateTime now = DateTime.now();
  return '${now.microsecond}';
}

String hashPassword(String plainPassword, String? salt) {
  salt ??= generateSalt();
  final c1 = Crypt.sha256('$salt$plainPassword');
  return '$salt$c1';
}

bool comparePassword(String plainPassword, String hashedPassword) {
  final salt = hashedPassword.substring(0, 16);
  final hashed = hashedPassword.substring(16);
  final c1 = Crypt.sha256('$salt$plainPassword');
  return c1.toString() == hashed;
}

String generateSalt() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));
  return base64Encode(values);
}

Future<FilePickerResult?> pickImage() async {
  return await FilePicker.platform.pickFiles(type: FileType.image);
}

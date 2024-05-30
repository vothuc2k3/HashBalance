import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypt/crypt.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';

import 'package:hash_balance/core/type_defs.dart';

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
  Future.delayed(const Duration(seconds: 3), () {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  });
}

FutureBool checkExistingUserName(String name) async {
  try {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: name)
        .get();

    if (result.docs.isNotEmpty) {
      return right(false);
    } else {
      return right(true);
    }
  } on FirebaseException catch (e) {
    return left(Failures(e.message!));
  } catch (e) {
    return left(Failures(e.toString()));
  }
}

void showMaterialBanner(BuildContext context, String text) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        forceActionsBelow: false,
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
  Future.delayed(const Duration(seconds: 3), () {
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    }
  });
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

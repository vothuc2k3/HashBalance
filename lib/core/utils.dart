import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';

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

FutureBool checkExistingUserName(String name, String uid) async {
  try {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: name)
        .get();
    final filteredDocs = result.docs.where((doc) => doc.id != uid).toList();

    if (filteredDocs.isNotEmpty) {
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

Future<FilePickerResult?> pickImage() async {
  return await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
  );
}

Future<FilePickerResult?> pickVideo() async {
  return await FilePicker.platform.pickFiles(type: FileType.video);
}

String generateRandomId() {
  var uuid = const Uuid();
  return uuid.v1();
}

String formatTime(Timestamp timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp.toDate());
  if (difference.inDays > 3) {
    return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
  } else {
    return timeago.format(timestamp.toDate(), locale: 'en_short');
  }
}

String getConversationId(String uid1, String uid2) {
  final uids = [uid1, uid2];
  uids.sort();
  return uids.join('_');
}

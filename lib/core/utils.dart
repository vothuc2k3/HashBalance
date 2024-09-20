import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:nanoid/async.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:hash_balance/core/failures.dart';
import 'package:toastification/toastification.dart';

void showToast(bool type, String message) {
  switch (type) {
    case true:
      toastification.show(
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        title: const Text('Success'),
        description: Text(message),
        alignment: Alignment.topLeft,
        autoCloseDuration: const Duration(seconds: 4),
        boxShadow: highModeShadow,
      );
      break;
    case false:
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: const Text('Failed'),
        description: Text(message),
        alignment: Alignment.topLeft,
        autoCloseDuration: const Duration(seconds: 4),
        boxShadow: highModeShadow,
      );
      break;
    default:
  }
}

Future<Either<Failures, bool>> checkExistingUserName(
    String name, String uid) async {
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

Future<Either<Failures, bool>> checkExistingEmailWhenSignUp(
    String email) async {
  try {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    if (result.docs.toList().isNotEmpty) {
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

Future<Either<Failures, bool>> checkExistingUserNameWhenSignUp(
    String name) async {
  try {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: name)
        .get();
    if (result.docs.toList().isNotEmpty) {
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

Future<FilePickerResult?> pickImage() async {
  return await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
  );
}

Future<FilePickerResult?> pickVideo() async {
  return await FilePicker.platform.pickFiles(type: FileType.video);
}

Future<String> generateRandomId() async {
  var id = await nanoid();
  return id;
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

String getUids(String uid1, String uid2) {
  final uids = [uid1, uid2];
  uids.sort();
  return uids.join('_');
}

String getMembershipId(String uid, String communityId) {
  return [uid, communityId].join();
}

String getPostUpvoteId(String uid, String postId) {
  return [uid, postId, 'upvote'].join();
}

String getPostDownvoteId(String uid, String postId) {
  return [uid, postId, 'downvote'].join();
}

String getUserDeviceDocId(String uid, String postId) {
  return [uid, postId, 'downvote'].join();
}

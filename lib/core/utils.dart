import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
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
  final result = await FilePicker.platform.pickFiles(type: FileType.video);
  if (result != null && result.files.first.size <= 200 * 1024 * 1024) {
    return result;
  } else {
    return null;
  }
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

String getMembershipId({
  required String uid,
  required String communityId,
}) {
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

void showImage(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void showCustomAlertDialog({
  required BuildContext context,
  required String title,
  required String content,
  required Color backgroundColor,
  required List<Widget> actions,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: backgroundColor,
      title: Text(title),
      content: Text(content),
      actions: actions,
    ),
  );
}

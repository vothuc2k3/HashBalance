import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
}

String generateCommunityId() {
  DateTime now = DateTime.now();
  String communityId =
      "${now.year}${now.month}${now.day}${now.hour}${now.minute}${now.second}${now.millisecond}";
  return communityId;
}

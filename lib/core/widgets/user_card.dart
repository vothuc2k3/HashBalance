// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/report/controller/report_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/user_model.dart';

class UserCard extends ConsumerWidget {
  final UserModel user;
  final Color theme;
  final VoidCallback onTap;
  final bool isAdmin;

  const UserCard({
    super.key,
    required this.user,
    required this.theme,
    required this.onTap,
    required this.isAdmin,
  });

  void _sendFriendRequest(WidgetRef ref) async {
    final result = await ref
        .read(friendControllerProvider.notifier)
        .sendFriendRequest(user);
    result.fold((l) {
      showToast(false, l.message);
    }, (r) {
      showToast(true, 'Friend request sent to ${user.name}');
    });
  }

  void _handleReportUser(BuildContext context, WidgetRef ref) async {
    if (user.uid == ref.read(userProvider)!.uid) {
      showToast(false, 'You cannot report yourself');
      return;
    }

    String? message = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String input = '';
        return AlertDialog(
          backgroundColor: theme,
          title: const Text('Report User'),
          content: TextField(
            onChanged: (value) {
              input = value;
            },
            decoration:
                const InputDecoration(hintText: "Enter reason for report"),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    ref.read(preferredThemeProvider).approveButtonColor,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(input);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    ref.read(preferredThemeProvider).declineButtonColor,
              ),
              child: const Text(
                'Submit',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (message != null && message.isNotEmpty) {
      final result = await ref.read(reportControllerProvider).addReport(
            null,
            null,
            user.uid,
            Constants.userReportType,
            null,
            message,
          );
      result.fold((l) {
        showToast(false, l.message);
      }, (r) {
        showToast(true, 'Report has been recorded!');
      });
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: theme,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.profileImage),
                radius: 35,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    if (user.bio != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.bio!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.white70),
                onSelected: (String value) {
                  Future.value(value).then((selectedValue) {
                    switch (selectedValue) {
                      case 'view':
                        onTap();
                        break;
                      case 'add_friend':
                        _sendFriendRequest(ref);
                        break;
                      case 'report':
                        _handleReportUser(context, ref);
                        break;
                    }
                  });
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'view',
                    child: Text('View Profile'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'add_friend',
                    child: Text('Add Friend'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'report',
                    child: Text('Report'),
                  ),
                  if (isAdmin)
                    const PopupMenuItem<String>(
                      value: 'suspend',
                      child: Text('Suspend This Account'),
                    ),
                  const PopupMenuItem<String>(
                    value: 'cancel',
                    child: Text('Cancel'),
                  ),
                ],
                color: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

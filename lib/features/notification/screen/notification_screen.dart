import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/constants.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/models/user_model.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends ConsumerState<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  Completer<void>? _completer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.5, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  void navigateToProfileScreen(String uid) async {
    final targetUser = await _fetchUserByUid(uid);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(
          targetUser: targetUser,
        ),
      ),
    );
  }

  void markAsRead(String notifId, UserModel user) {
    ref.watch(notificationControllerProvider.notifier).markAsRead(notifId);
    setState(() {});
  }

  void deleteNotification(String notifId) async {
    ref.watch(deleteNotifProvider(notifId));
    setState(() {});
  }

  Future<UserModel> _fetchUserByUid(String uid) async {
    return ref
        .watch(userControllerProvider.notifier)
        .fetchUserByUidProvider(uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return ref.watch(getNotifsProvider(user!.uid)).when(
          data: (notifs) {
            if (notifs == null || notifs.isEmpty) {
              return Scaffold(
                body: Center(
                  child: const Text(
                    'You have no new notifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ).animate().fadeIn(duration: 600.ms).moveY(
                        begin: 30,
                        end: 0,
                        duration: 600.ms,
                        curve: Curves.easeOutBack,
                      ),
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                return ListView.builder(
                  itemCount: notifs.length,
                  itemBuilder: (context, index) {
                    var notif = notifs[index];
                    var timeString = formatTime(notif.createdAt);
                    return SlideTransition(
                      position: _offsetAnimation,
                      child: Dismissible(
                        key: Key(notif.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          deleteNotification(notif.id);
                          _controller.reverse();
                          _completer?.complete();
                        },
                        confirmDismiss: (direction) async {
                          _controller.forward();
                          _completer = Completer<void>();
                          await _completer!.future;
                          return true;
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: GestureDetector(
                          onTap: () async {
                            if (_controller.isCompleted) {
                              deleteNotification(notif.id);
                              _controller.reverse();
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: notif.isRead == true
                                  ? Colors.grey[850]
                                  : Colors.blueGrey[700],
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                notif.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif.message,
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    timeString,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: notif.isRead == true
                                  ? null
                                  : const Icon(Icons.new_releases,
                                      color: Colors.red),
                              onTap: () async {
                                markAsRead(notif.id, user);
                                switch (notif.type) {
                                  case Constants.friendRequestType:
                                    navigateToProfileScreen(notif.senderUid);
                                    break;
                                  case Constants.acceptRequestType:
                                    navigateToProfileScreen(notif.senderUid);
                                    break;
                                  default:
                                }
                              },
                            ).animate().fadeIn(duration: 600.ms).moveY(
                                  begin: 30,
                                  end: 0,
                                  duration: 600.ms,
                                  curve: Curves.easeOutBack,
                                ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
          error: (error, stackTrace) => ErrorText(error: error.toString()),
          loading: () => const Loading(),
        );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';

import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends ConsumerState<NotificationScreen> {
  void _navigateToCommunityScreen(
    String communityId,
    String uid,
  ) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
    String? membershipStatus;
    Community? community;
    final result = await ref
        .watch(moderationControllerProvider.notifier)
        .fetchMembershipStatus(getMembershipId(uid, communityId));

    result.fold(
      (l) {
        showToast(false, 'Unexpected error happened...');
      },
      (r) async {
        membershipStatus = r;
        community = await _fetchCommunityById(communityId);
        if (mounted && community != null) {
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityScreen(
                memberStatus: membershipStatus!,
                community: community!,
              ),
            ),
          );
        }
      },
    );
  }

  void _navigateToProfileScreen(String uid) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
    final targetUser = await _fetchUserByUid(uid);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OtherUserProfileScreen(
            targetUser: targetUser,
          ),
        ),
      );
    }
  }

  void _markAsRead(String notifId, UserModel user) {
    ref.watch(notificationControllerProvider.notifier).markAsRead(notifId);
    setState(() {});
  }

  void _deleteNotification(String notifId) async {
    ref.watch(deleteNotifProvider(notifId));
    setState(() {});
  }

  Future<UserModel> _fetchUserByUid(String uid) async {
    return ref
        .watch(userControllerProvider.notifier)
        .fetchUserByUidProvider(uid);
  }

  Future<Community> _fetchCommunityById(String communityId) async {
    return ref
        .watch(communityControllerProvider.notifier)
        .fetchCommunityById(communityId);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000),
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: ref.watch(getNotifsProvider(user!.uid)).when(
              data: (notifs) {
                if (notifs == null || notifs.isEmpty) {
                  return Center(
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
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return ListView.builder(
                      itemCount: notifs.length,
                      itemBuilder: (context, index) {
                        var notif = notifs[index];
                        var timeString = formatTime(notif.createdAt);
                        return Slidable(
                          key: Key(notif.id),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            dismissible: DismissiblePane(
                              onDismissed: () {
                                _deleteNotification(notif.id);
                              },
                            ),
                            children: [
                              SlidableAction(
                                onPressed: (context) =>
                                    _deleteNotification(notif.id),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                              ),
                            ],
                          ),
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
                                _markAsRead(notif.id, user);
                                switch (notif.type) {
                                  case Constants.friendRequestType:
                                    _navigateToProfileScreen(notif.senderUid);
                                    break;
                                  case Constants.acceptRequestType:
                                    _navigateToProfileScreen(notif.senderUid);
                                    break;
                                  case Constants.moderatorInvitationType:
                                    _navigateToCommunityScreen(
                                        notif.communityId!, user.uid);
                                    break;
                                  default:
                                    break;
                                }
                              },
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
            ),
      ),
    );
  }
}

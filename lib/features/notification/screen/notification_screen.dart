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
import 'package:hash_balance/features/community/controller/community_controller.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/post/screen/post_detail_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/models/notification_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:logger/logger.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends ConsumerState<NotificationScreen> {
  List<NotificationModel>? _notifications = [];
  NotificationModel? _lastNotification;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMoreNotifications = false;

  Future<void> _clearAllNotifications() async {
    final result = await ref
        .read(notificationControllerProvider.notifier)
        .clearAllNotifications();
    result.fold(
      (l) => showToast(false, l.message),
      (r) => showToast(true, 'All notifications cleared.'),
    );
  }

  void _onScroll() async {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMoreNotifications) {
      Logger().d('ONSCROLLLLLLLL');

      await _loadMoreNotifications();
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_lastNotification == null) return;
    setState(() {
      _isLoadingMoreNotifications = true;
    });

    final moreNotifications = await ref
        .read(notificationControllerProvider.notifier)
        .loadMoreNotifications(_lastNotification!);

    if (moreNotifications != null && moreNotifications.isNotEmpty) {
      setState(() {
        _notifications!.addAll(moreNotifications);
        _lastNotification = moreNotifications.last;
      });
    }

    setState(() {
      _isLoadingMoreNotifications = false;
    });
  }

  void _navigateToPostDetailScreen(String postId) async {
    final result = await ref
        .read(postControllerProvider.notifier)
        .getPostDataByPostId(postId: postId);
    result.fold(
      (l) => showToast(false, l.message),
      (postData) {
        if (postData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(
                author: postData.author!,
                community: postData.community!,
                post: postData.post,
              ),
            ),
          );
        }
      },
    );
  }

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
    final result = await ref
        .read(communityControllerProvider.notifier)
        .fetchSuspendStatus(communityId: communityId, uid: uid);
    result.fold(
      (l) {
        showToast(false, 'Unexpected error happened...');
      },
      (r) {
        if (r) {
          showToast(false, 'You are suspended from this community');
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityScreen(
                communityId: communityId,
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
          builder: (context) =>
              OtherUserProfileScreen(targetUid: targetUser.uid),
        ),
      );
    }
  }

  void _markAsRead(String notifId, UserModel user) async {
    await ref.read(notificationControllerProvider.notifier).markAsRead(notifId);
  }

  void _deleteNotification(String notifId) async {
    ref.watch(deleteNotifProvider(notifId));
  }

  Future<UserModel> _fetchUserByUid(String uid) async {
    return ref
        .watch(userControllerProvider.notifier)
        .fetchUserByUidProvider(uid);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  void deactivate() {
    _scrollController.removeListener(_onScroll);
    super.deactivate();
  }

  @override
  void reassemble() {
    _scrollController.addListener(_onScroll);
    super.reassemble();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final notifsAsyncValue = ref.watch(getInitialNotifsProvider(user!.uid));
    return Scaffold(
      body: Container(
        color: ref.watch(preferredThemeProvider).first,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (notifsAsyncValue.value != null &&
                    notifsAsyncValue.value!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0, top: 10.0),
                    child: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor:
                                  ref.watch(preferredThemeProvider).first,
                              title: const Text(
                                'Clear All Notifications',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              content: const Text(
                                'Are you sure you want to clear all notifications?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _clearAllNotifications();
                                  },
                                  child: const Text(
                                    'Clear All',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Clear All Notifications'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: notifsAsyncValue.when(
                data: (notifs) {
                  _notifications = notifs;
                  _lastNotification =
                      (_notifications != null && _notifications!.isNotEmpty)
                          ? _notifications!.last
                          : null;

                  if (_notifications?.isEmpty ?? true) {
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

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: _notifications!.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _notifications!.length) {
                        return _isLoadingMoreNotifications
                            ? const Center(child: Loading())
                            : const SizedBox.shrink();
                      }

                      final notif = _notifications![index];
                      final timeString = formatTime(notif.createdAt);

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
                              spacing: 8,
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
                            color: notif.isRead
                                ? ref.watch(preferredThemeProvider).second
                                : ref.watch(preferredThemeProvider).third,
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
                                  style: const TextStyle(color: Colors.white70),
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
                            onTap: () {
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
                                case Constants.newFollowerType:
                                  _navigateToProfileScreen(notif.senderUid);
                                  break;
                                case Constants.commentMentionType:
                                  _navigateToPostDetailScreen(notif.postId!);
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
                error: (error, stackTrace) =>
                    ErrorText(error: error.toString()),
                loading: () => const Loading(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

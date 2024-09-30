import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:logger/logger.dart';

class MembershipManagementScreen extends ConsumerStatefulWidget {
  final Community _community;

  const MembershipManagementScreen({
    super.key,
    required Community community,
  }) : _community = community;

  @override
  ConsumerState<MembershipManagementScreen> createState() =>
      _MembershipManagementScreenState();
}

class _MembershipManagementScreenState
    extends ConsumerState<MembershipManagementScreen> {
  String? suspendedUserReason;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Management'),
        backgroundColor: ref.watch(preferredThemeProvider).second,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
        ),
        child: Column(
          children: [
            Expanded(
              child: ref
                  .watch(fetchInitialCommunityMembersProvider(
                      widget._community.id))
                  .when(
                    data: (members) {
                      return ListView.builder(
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final currentUser = ref.read(userProvider)!;
                          final isCurrentUser =
                              member.user.uid == currentUser.uid;

                          return ExpansionTile(
                            leading: CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  member.user.profileImage),
                            ),
                            title: Text(
                              isCurrentUser
                                  ? '${member.user.name} (You)'
                                  : member.user.name,
                              style: TextStyle(
                                fontWeight: isCurrentUser
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (!isCurrentUser)
                                      ElevatedButton(
                                        onPressed: () =>
                                            _sendInvite(member.user),
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.teal,
                                        ),
                                        child: const Text('Send Invite'),
                                      ),
                                    const SizedBox(width: 10),
                                    if (!isCurrentUser)
                                      ElevatedButton(
                                        onPressed: () =>
                                            _handleSuspendMember(member.user),
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.redAccent,
                                        ),
                                        child: const Text('Suspend'),
                                      ),
                                    if (isCurrentUser)
                                      ElevatedButton(
                                        onPressed: () =>
                                            _leaveCommunity(currentUser),
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.redAccent,
                                        ),
                                        child: const Text('Leave'),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    error: (error, stack) => Center(
                      child: Text(error.toString()).animate().shimmer(
                        colors: [Colors.grey, Colors.white],
                      ),
                    ),
                    loading: () => const Center(
                      child: Loading(),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _leaveCommunity(UserModel user) async {
    // Logic to leave the community
  }

  void _handleSuspendMember(UserModel user) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: ref.watch(preferredThemeProvider).second,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(vertical: 10),
              ),
              const Text(
                'Suspend Member',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                title:
                    const Text('1 Day', style: TextStyle(color: Colors.white)),
                onTap: () =>
                    _suspendUserDuration(user, const Duration(days: 1)),
              ),
              ListTile(
                title:
                    const Text('3 Days', style: TextStyle(color: Colors.white)),
                onTap: () =>
                    _suspendUserDuration(user, const Duration(days: 3)),
              ),
              ListTile(
                title:
                    const Text('7 Days', style: TextStyle(color: Colors.white)),
                onTap: () =>
                    _suspendUserDuration(user, const Duration(days: 7)),
              ),
              ListTile(
                title: const Text('1 Month',
                    style: TextStyle(color: Colors.white)),
                onTap: () =>
                    _suspendUserDuration(user, const Duration(days: 30)),
              ),
              ListTile(
                title: const Text('3 Months',
                    style: TextStyle(color: Colors.white)),
                onTap: () =>
                    _suspendUserDuration(user, const Duration(days: 90)),
              ),
              ListTile(
                title: const Text('6 Months',
                    style: TextStyle(color: Colors.white)),
                onTap: () =>
                    _suspendUserDuration(user, const Duration(days: 180)),
              ),
              ListTile(
                title: const Text('12 Months',
                    style: TextStyle(color: Colors.white)),
                onTap: () =>
                    _suspendUserDuration(user, const Duration(days: 365)),
              ),
              ListTile(
                title: const Text('Permanent',
                    style: TextStyle(color: Colors.white)),
                onTap: () => _suspendUserPer(user),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _suspendUserDuration(UserModel user, Duration duration) async {
    Navigator.pop(context);

    final bool? result = await _showSuspendConfirmationDialog(duration, false);

    if (result == true) {
      suspendedUserReason = await _showSelectReasonDialog();
      if (suspendedUserReason != null) {
        _suspendUserForDays(
            user: user, reason: suspendedUserReason!, duration: duration);
        suspendedUserReason = null;
      }
    }
  }

  void _suspendUserPer(UserModel user) async {
    Navigator.pop(context);

    final bool? result = await _showSuspendConfirmationDialog(null, true);

    if (result == true) {
      suspendedUserReason = await _showSelectReasonDialog();

      if (suspendedUserReason != null) {
        _suspendUserPermanently(
            user: user, isPermanent: true, reason: suspendedUserReason!);
        suspendedUserReason = null;
      }
    }
  }

  Future<bool?> _showSuspendConfirmationDialog(
      Duration? duration, bool isPermanent) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text('Suspend Member',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          content: Text(
            isPermanent
                ? 'Are you sure you want to suspend this user permanently?'
                : 'Are you sure you want to suspend this user for ${duration!.inDays} days?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'No',
                style: TextStyle(color: Colors.greenAccent),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Yes',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

// Hàm hiển thị hộp thoại chọn lý do
  Future<String?> _showSelectReasonDialog() async {
    final List<String> reasons = [
      'Spamming',
      'Inappropriate behavior',
      'Hate speech',
      'Violating community rules',
      'Other'
    ];

    String selectedReason = reasons.first;

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text(
            'Select Reason',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: DropdownButtonFormField<String>(
            dropdownColor: ref.watch(preferredThemeProvider).second,
            value: selectedReason,
            items: reasons.map((reason) {
              return DropdownMenuItem(
                value: reason,
                child: Text(
                  reason,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (value) {
              selectedReason = value!;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: ref.watch(preferredThemeProvider).second,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(selectedReason),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.greenAccent),
              ),
            ),
          ],
        );
      },
    );
    Logger().d('Selected reason: $reason');
    return reason;
  }

  void _suspendUserPermanently({
    required UserModel user,
    Duration? duration,
    required bool isPermanent,
    required String reason,
  }) async {
    Logger().d('REACH THIS POINT, isPermanent?: $isPermanent');
    if (isPermanent == true) {
      final result =
          await ref.read(moderationControllerProvider.notifier).suspendUser(
                uid: user.uid,
                communityId: widget._community.id,
                isPermanent: isPermanent,
                reason: reason,
                expiresAt: Timestamp.fromDate(
                  DateTime.now(),
                ),
              );
      result.fold(
        (l) => showToast(false, l.message),
        (r) => showToast(
            true, 'User ${user.name} suspended permanently. Reason: $reason'),
      );
    } else if (isPermanent == false) {
      Logger().d('Suspending user for ${duration!.inDays} days');
      final result =
          await ref.read(moderationControllerProvider.notifier).suspendUser(
                uid: user.uid,
                communityId: widget._community.id,
                isPermanent: isPermanent,
                reason: reason,
                expiresAt: Timestamp.fromDate(
                  DateTime.now().add(duration),
                ),
              );
      result.fold(
        (l) => showToast(false, l.message),
        (r) => showToast(true,
            'User ${user.name} suspended for ${duration.inDays} days. Reason: $reason'),
      );
    } else {
      showToast(false, 'Unexpected error happenned :(');
    }
  }

  void _suspendUserForDays({
    required UserModel user,
    required Duration duration,
    required String reason,
  }) async {
    final result =
        await ref.read(moderationControllerProvider.notifier).suspendUser(
              uid: user.uid,
              communityId: widget._community.id,
              isPermanent: false,
              reason: reason,
              expiresAt: Timestamp.fromDate(
                DateTime.now().add(duration),
              ),
            );
    result.fold(
      (l) => showToast(false, l.message),
      (r) => showToast(true,
          'User ${user.name} suspended for ${duration.inDays} days. Reason: $reason'),
    );
  }

  void _sendInvite(UserModel friend) async {
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .inviteAsModerator(friend.uid, widget._community);
    result.fold(
      (l) => showToast(false, l.message),
      (r) {
        showToast(true, 'Invite sent to ${friend.name}');
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/user_profile/screen/widget/other_profile_widget.dart';
import 'package:hash_balance/features/user_profile/screen/widget/user_timeline_widget.dart';
import 'package:tuple/tuple.dart';

class OtherUserProfileScreen extends ConsumerStatefulWidget {
  final String targetUid;

  const OtherUserProfileScreen({
    super.key,
    required this.targetUid,
  });

  @override
  ConsumerState<OtherUserProfileScreen> createState() =>
      _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState
    extends ConsumerState<OtherUserProfileScreen> {
  int selectedIndex = 0;

  String get _uid => widget.targetUid;

  void _blockUser(String blockUid, String currentUid) async {
    final result = await ref.read(userControllerProvider.notifier).blockUser(
          currentUid: currentUid,
          blockUid: blockUid,
        );
    result.fold((l) {
      showToast(false, l.message);
    }, (_) {
      showToast(true, 'User blocked');
    });
  }

  void _unblockUser(String targetUid, String currentUid) async {
    final result = await ref.read(userControllerProvider.notifier).unblockUser(
          currentUid: currentUid,
          blockUid: targetUid,
        );
    result.fold((l) {
      showToast(false, l.message);
    }, (_) {
      showToast(true, 'User unblocked');
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void _showMoreOptions(String currentUid, bool hasBlocked) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: ref.watch(preferredThemeProvider).first,
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.call),
                title: const Text('Audio call'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Video call'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Report profile'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text(hasBlocked ? 'Unblock' : 'Block'),
                onTap: () {
                  hasBlocked
                      ? _unblockUser(_uid, currentUid)
                      : _blockUser(_uid, currentUid);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider)!;
    return Scaffold(
      backgroundColor: ref.watch(preferredThemeProvider).first,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          ref
                  .watch(isBlockedByCurrentUserProvider(
                      Tuple2(currentUser.uid, _uid)))
                  .whenOrNull(
                data: (hasBlocked) {
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () =>
                            _showMoreOptions(currentUser.uid, hasBlocked),
                        icon: const Icon(
                          FontAwesomeIcons.ellipsisVertical,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ) ??
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  FontAwesomeIcons.ellipsisVertical,
                  color: Colors.white,
                ),
              ),
        ],
      ),
      body: ref.watch(getUserDataProvider(_uid)).when(
            data: (user) {
              return selectedIndex == 0
                  ? OtherUserProfileWidget(user: user)
                  : UserTimelineWidget(user: user);
            },
            error: (error, stack) => ErrorText(error: error.toString()),
            loading: () => const Loading(),
          ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Timeline',
          ),
        ],
      ),
    );
  }
}

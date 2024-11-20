import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/message/screen/private_message_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/friends/mutual_friends_screen.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:tuple/tuple.dart';

class OtherUserProfileWidget extends ConsumerStatefulWidget {
  final UserModel user;

  const OtherUserProfileWidget({super.key, required this.user});

  @override
  ConsumerState<OtherUserProfileWidget> createState() =>
      _OtherUserProfileWidgetState();
}

class _OtherUserProfileWidgetState
    extends ConsumerState<OtherUserProfileWidget> {
  final double coverHeight = 250;
  final double profileHeight = 120;

  UserModel get _user => widget.user;

  void _cancelFriendRequest(String requestId) async {
    final result = await ref
        .read(friendControllerProvider.notifier)
        .cancelFriendRequest(requestId);
    result.fold((l) {
      showToast(false, l.message);
    }, (_) {});
  }

  void _acceptFriendRequest(UserModel targetUser) async {
    final result = await ref
        .read(friendControllerProvider.notifier)
        .acceptFriendRequest(targetUser);
    result.fold((l) {
      showToast(false, l.message);
    }, (_) {});
  }

  void _sendAddFriendRequest(UserModel targetUser) async {
    final result = await ref
        .read(friendControllerProvider.notifier)
        .sendFriendRequest(targetUser);
    result.fold((l) {
      showToast(false, l.message);
    }, (_) {});
  }

  void _unfriend(UserModel targetUser) async {
    final result = await ref
        .read(friendControllerProvider.notifier)
        .unfriend(targetUser.uid);
    result.fold((l) {
      showToast(false, l.message);
    }, (_) {});
  }

  void _messageUser(UserModel targetUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateMessageScreen(
          targetUser: targetUser,
        ),
      ),
    );
  }

  void _followUser(UserModel targetUser) async {
    final result = await ref
        .read(friendControllerProvider.notifier)
        .followUser(targetUser.uid);
    result.fold((l) {
      showToast(false, l.message);
    }, (_) {});
  }

  void _unfollowUser(UserModel targetUser) async {
    final result = await ref
        .read(friendControllerProvider.notifier)
        .unfollowUser(targetUser.uid);
    result.fold((l) {
      showToast(false, l.message);
    }, (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider);
    final uids = getUids(currentUser!.uid, _user.uid);
    final combinedStatus = ref
        .watch(getCombinedStatusProvider(Tuple2(currentUser.uid, _user.uid)));

    final double top = coverHeight - profileHeight / 2;
    final double bottom = profileHeight / 2;
    return Scaffold(
      body: Container(
        color: ref.watch(preferredThemeProvider).first,
        child: ref.watch(getUserDataProvider(_user.uid)).when(
              data: (user) {
                return combinedStatus.when(
                    data: (data) {
                      return ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: bottom),
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: user.bannerImage,
                                  width: double.infinity,
                                  height: coverHeight,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: double.infinity,
                                    height: coverHeight,
                                    color: Colors.black,
                                    child: const Center(
                                      child: Loading(),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: top,
                                  child: CircleAvatar(
                                    radius: profileHeight / 2,
                                    backgroundColor: Colors.grey.shade800,
                                    backgroundImage: CachedNetworkImageProvider(
                                      user.profileImage,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1.5, 1.5),
                                        blurRadius: 3.0,
                                        color: Colors.black26,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user.bio ?? 'No bio available...',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  user.description ??
                                      'No description available...',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    letterSpacing: 0.5,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  children: [
                                    const SizedBox(height: 8, width: 8),
                                    //BUILD FOLLOWING WIDGET
                                    _buildFollowButton(
                                      data.item3,
                                      _followUser,
                                      _unfollowUser,
                                      user,
                                    ),
                                    //BUILD FRIEND WIDGET
                                    const SizedBox(height: 8, width: 8),
                                    data.item4
                                        ? _buildFriendsWidget(
                                                context, user, _unfriend)
                                            .animate()
                                        : ref
                                            .watch(
                                                getFriendRequestStatusProvider(
                                                    uids))
                                            .when(
                                              data: (request) {
                                                if (request == null) {
                                                  return Column(
                                                    children: [
                                                      _buildAddFriendButton(
                                                              _sendAddFriendRequest,
                                                              user)
                                                          .animate(),
                                                    ],
                                                  );
                                                } else if (request.requestUid ==
                                                        currentUser.uid &&
                                                    request.status ==
                                                        Constants
                                                            .friendRequestStatusPending) {
                                                  return _buildFriendRequestSent(
                                                          _cancelFriendRequest,
                                                          uids)
                                                      .animate();
                                                } else {
                                                  return _buildAcceptFriendRequestButton(
                                                    _acceptFriendRequest,
                                                    _cancelFriendRequest,
                                                    user,
                                                    uids,
                                                  ).animate();
                                                }
                                              },
                                              error: (error, stackTrace) =>
                                                  ErrorText(
                                                          error:
                                                              error.toString())
                                                      .animate(),
                                              loading: () =>
                                                  const Loading().animate(),
                                            ),
                                    //BUILD MESSAGE USER
                                    const SizedBox(height: 8, width: 8),
                                    data.item4
                                        ? _buildMessageButton(
                                            onPressed: _messageUser,
                                            targetUser: user,
                                            isBlocked: data.item2,
                                          )
                                        : const SizedBox.shrink(),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildButton(text: 'Friends', value: 52),
                                    _buildVerticalDivider(),
                                    _buildButton(
                                      text: 'Points',
                                      value: user.activityPoint,
                                    ),
                                    _buildVerticalDivider(),
                                    _buildButton(
                                        text: 'Achievements', value: 0),
                                    _buildVerticalDivider(),
                                    _buildButton(
                                        text: 'Followers', value: 5834),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 16),
                                _buildAllFriendsWidget(
                                    user.uid, currentUser.uid),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    error: (error, stackTrace) =>
                        ErrorText(error: error.toString()),
                    loading: () => const Loading());
              },
              error: (error, stackTrace) => ErrorText(error: error.toString()),
              loading: () => const Loading(),
            ),
      ),
    );
  }

  Widget _buildAllFriendsWidget(String uid, String currentUserUid) {
    return ref.watch(fetchFriendsProvider(uid)).when(
          data: (friendList) {
            if (friendList.isEmpty) {
              return const SizedBox.shrink();
            } else {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ref
                        .watch(mutualFriendsCountProvider(
                            Tuple2(currentUserUid, uid)))
                        .whenOrNull(
                          data: (mutualFriendsCount) => GestureDetector(
                            onTap: () => _navigateToMutualFriendsScreen(uid),
                            child: Text(
                              'Mutual Friends: $mutualFriendsCount',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1.5, 1.5),
                                    blurRadius: 3.0,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          error: (error, stackTrace) => ErrorText(
                            error: error.toString(),
                          ),
                          loading: () => const Loading(),
                        ),
                  ),
                  SizedBox(
                    height: 250,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: friendList.length,
                      itemBuilder: (context, index) {
                        final friend = friendList[index];
                        return Column(
                          children: [
                            InkWell(
                              onTap: () => _navigateToFriendProfile(
                                friend,
                                currentUserUid,
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: CachedNetworkImageProvider(
                                  friend.profileImage,
                                ),
                                child: friend.profileImage.isEmpty
                                    ? const Icon(Icons.error)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              friend.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.black.withOpacity(0.25),
                      ).copyWith(
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                      ),
                      onPressed: () {},
                      child: Ink(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          constraints: const BoxConstraints(minHeight: 50),
                          child: const Text(
                            'See all friends',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 3),
                                  blurRadius: 6.0,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ).animate().fadeIn();
            }
          },
          error: (error, stackTrace) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          loading: () => const Center(child: Loading()),
        );
  }

  void _navigateToMutualFriendsScreen(String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MutualFriendsScreen(uid: uid)),
    );
  }

  Widget _buildFollowButton(
    bool isFollowing,
    dynamic followUser,
    dynamic unfollowUser,
    UserModel targetUser,
  ) {
    return isFollowing
        ? ElevatedButton.icon(
            onPressed: () => unfollowUser(targetUser),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Following'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 5,
            ),
          ).animate().fadeIn(duration: 600.ms).moveY(
            begin: 30, end: 0, duration: 600.ms, curve: Curves.easeOutBack)
        : ElevatedButton.icon(
            onPressed: () {
              followUser(targetUser);
            },
            icon: const Icon(Icons.person_pin, color: Colors.white),
            label: const Text('Follow'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 5,
            ),
          ).animate().fadeIn(duration: 600.ms).moveY(
            begin: 30, end: 0, duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildAcceptFriendRequestButton(
    dynamic accept,
    dynamic cancel,
    UserModel targetUser,
    String uids,
  ) {
    return PopupMenuButton<int>(
      onSelected: (value) {
        if (value == 1) {
          accept(targetUser);
        } else if (value == 2) {
          cancel(uids);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 1,
          child: ListTile(
            leading: Icon(Icons.check, color: Colors.green),
            title: Text('Accept'),
          ),
        ),
        const PopupMenuItem(
          value: 2,
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete'),
          ),
        ),
      ],
      child: InkWell(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 4),
                blurRadius: 5,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Friend Request',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(),
    );
  }

  Widget _buildFriendRequestSent(dynamic cancel, String requestUid) {
    return ElevatedButton.icon(
      onPressed: () {
        _showCancelFriendRequestDialog(cancel, requestUid);
      },
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      label: const Text('Request Sent'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 5,
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .moveY(begin: 30, end: 0, duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildAddFriendButton(dynamic onPressed, UserModel targetUser) {
    return ElevatedButton.icon(
      onPressed: () {
        onPressed(targetUser);
      },
      icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
      label: const Text('Add Friend'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 5,
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .moveY(begin: 30, end: 0, duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildMessageButton({
    required Function(UserModel) onPressed,
    required UserModel targetUser,
    required bool isBlocked,
  }) {
    return ElevatedButton.icon(
            onPressed: isBlocked
                ? () => showToast(false, 'You are blocked by this user')
                : () => onPressed(targetUser),
            icon: const Icon(Icons.message, color: Colors.white),
            label: const Text('Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBlocked ? Colors.grey : Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 5,
            )).animate().fadeIn(duration: 600.ms).moveY(
          begin: 30,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildFriendsWidget(
    BuildContext context,
    UserModel targetUser,
    dynamic unfriend,
  ) {
    return ElevatedButton.icon(
      onPressed: () => _showUnfriendDialog(
        context,
        targetUser,
        unfriend,
      ),
      icon: const Icon(Icons.people, color: Colors.white),
      label: const Text('Friends'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 5,
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .moveY(begin: 30, end: 0, duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildButton({
    required String text,
    required int value,
  }) {
    return Expanded(
      child: MaterialButton(
        padding: const EdgeInsets.symmetric(vertical: 4),
        onPressed: () {},
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return const VerticalDivider(
      width: 0.1,
      thickness: 1,
      color: Colors.grey,
    );
  }

  void _showCancelFriendRequestDialog(dynamic cancel, String requestId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text('Cancel Friend Request'),
          content: const Text(
              'Are you sure you want to cancel this friend request?'),
          actions: <Widget>[
            TextButton(
              child:
                  const Text('No', style: TextStyle(color: Colors.greenAccent)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
              onPressed: () {
                cancel(requestId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showUnfriendDialog(
    BuildContext context,
    UserModel targetUser,
    dynamic unfriend,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text('Unfriend'),
          content: const Text('Do you want to unfriend this user?'),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'No',
                style: TextStyle(
                  color: Colors.green,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
                child: const Text(
                  'Yes',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
                onPressed: () {
                  unfriend(targetUser);
                  Navigator.of(context).pop();
                }),
          ],
        );
      },
    );
  }

  void _navigateToFriendProfile(UserModel friend, String currentUserUid) {
    if (friend.uid == currentUserUid) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UserProfileScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherUserProfileScreen(targetUid: friend.uid),
        ),
      );
    }
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/message/screen/private_message_screen.dart';
import 'package:hash_balance/models/user_model.dart';

class OtherUserProfileScreen extends ConsumerStatefulWidget {
  const OtherUserProfileScreen({
    super.key,
    required UserModel targetUser,
  }) : _targetUser = targetUser;

  final UserModel _targetUser;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState
    extends ConsumerState<OtherUserProfileScreen> {
  final double coverHeight = 250;
  final double profileHeight = 120;

  void followUser(UserModel targetUser) async {
    final result = await ref
        .watch(friendControllerProvider.notifier)
        .followUser(targetUser.uid);
    result.fold((l) {
      showToast(false, l.message);
    }, (_) {});
  }

  void sendAddFriendRequest(UserModel targetUser) async {
    final result = await ref
        .watch(friendControllerProvider.notifier)
        .sendFriendRequest(targetUser);
    result.fold((l) {
      showToast(false, l.message);
    }, (_) {});
  }

  void cancelFriendRequest(String requestId) async {
    final result = await ref
        .watch(friendControllerProvider.notifier)
        .cancelFriendRequest(requestId);
    result.fold((l) {
      showToast(false, l.message);
    }, (_) {});
  }

  void acceptFriendRequest(UserModel targetUser) async {
    final result = await ref
        .watch(friendControllerProvider.notifier)
        .acceptFriendRequest(targetUser);
    result.fold((l) {
      showToast(false, l.message);
    }, (_) {});
  }

  void unfriend(UserModel targetUser) async {
    final result =
        await ref.watch(friendControllerProvider.notifier).unfriend(targetUser);
    result.fold((l) {
      showToast(false, l.message);
    }, (_) {});
  }

  void messageUser(UserModel targetUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageScreen(
          targetUser: targetUser,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget._targetUser.isRestricted) {
        _showRestrictedProfileDialog();
      }
    });
  }

  void _showRestrictedProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restricted Profile'),
          content: const Text(
              'This user currently does not allow their profile to be viewed.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider);
    final isFollowing =
        ref.watch(getFollowingStatusProvider(widget._targetUser));
    final isFriend = ref.watch(getFriendshipStatusProvider(widget._targetUser));
    final requestId = getUids(currentUser!.uid, widget._targetUser.uid);

    final double top = coverHeight - profileHeight / 2;
    final double bottom = profileHeight / 2;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          widget._targetUser.name,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: bottom),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    color: Colors.grey,
                    child: CachedNetworkImage(
                      imageUrl: widget._targetUser.bannerImage,
                      width: double.infinity,
                      height: coverHeight,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: double.infinity,
                        height: coverHeight,
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: top,
                    child: CircleAvatar(
                      radius: profileHeight / 2,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: CachedNetworkImageProvider(
                        widget._targetUser.profileImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    widget._targetUser.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget._targetUser.bio ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget._targetUser.description ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialIcon(FontAwesomeIcons.slack),
                      const SizedBox(width: 12),
                      _buildSocialIcon(FontAwesomeIcons.github),
                      const SizedBox(width: 12),
                      _buildSocialIcon(FontAwesomeIcons.twitter),
                      const SizedBox(width: 12),
                      _buildSocialIcon(FontAwesomeIcons.linkedin),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(height: 8),
                      //BUILD FOLLOWING WIDGET
                      isFollowing.when(
                        data: (isFollowing) {
                          return _buildFollowButton(
                            isFollowing,
                            followUser,
                            widget._targetUser,
                          );
                        },
                        error: (error, stackTrace) =>
                            ErrorText(error: error.toString()),
                        loading: () => const Loading(),
                      ),
                      //BUILD FRIEND WIDGET
                      const SizedBox(height: 8),
                      isFriend.when(
                          data: (isFriend) {
                            return isFriend == true
                                ? _buildFriendsWidget(
                                    context,
                                    widget._targetUser,
                                    unfriend,
                                  ).animate()
                                : ref
                                    .watch(getFriendRequestStatusProvider(
                                        requestId))
                                    .when(
                                      data: (request) {
                                        if (request == null) {
                                          return Column(
                                            children: [
                                              _buildAddFriendButton(
                                                sendAddFriendRequest,
                                                widget._targetUser,
                                              ).animate(),
                                            ],
                                          );
                                        } else if (request.requestUid ==
                                            currentUser.uid) {
                                          return _buildFriendRequestSent(
                                                  cancelFriendRequest,
                                                  requestId)
                                              .animate();
                                        } else {
                                          return _buildAcceptFriendRequestButton(
                                            acceptFriendRequest,
                                            cancelFriendRequest,
                                            widget._targetUser,
                                            requestId,
                                          ).animate();
                                        }
                                      },
                                      error: (error, stackTrace) =>
                                          ErrorText(error: error.toString())
                                              .animate(),
                                      loading: () => const Loading().animate(),
                                    );
                          },
                          error: (error, stackTrace) =>
                              ErrorText(error: error.toString()),
                          loading: () => const Loading()),
                      //BUILD MESSAGE USER
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          messageUser(widget._targetUser);
                        },
                        icon: const Icon(Icons.message, color: Colors.white),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 5,
                        ),
                      ).animate().fadeIn(duration: 600.ms).moveY(
                            begin: 30,
                            end: 0,
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          ),
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
                        value: widget._targetUser.activityPoint,
                      ),
                      _buildVerticalDivider(),
                      _buildButton(text: 'Achievements', value: 0),
                      _buildVerticalDivider(),
                      _buildButton(text: 'Followers', value: 5834),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(
    bool isFollowing,
    dynamic followUser,
    UserModel targetUser,
  ) {
    return isFollowing
        ? ElevatedButton.icon(
            onPressed: () {
              followUser(targetUser);
            },
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
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
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

  Widget _buildSocialIcon(IconData icon) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.blueAccent,
      child: Material(
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Center(
            child: Icon(
              icon,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
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
    // required Function(dynamic) function,
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
          title: const Text('Cancel Friend Request'),
          content: const Text(
              'Are you sure you want to cancel this friend request?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
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
          title: const Text('Unfriend'),
          content: const Text('Do you want to unfriend this user?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
                child: const Text('Yes'),
                onPressed: () {
                  unfriend(targetUser);
                  Navigator.of(context).pop();
                }),
          ],
        );
      },
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/friends/controller/friend_controller.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:routemaster/routemaster.dart';

class OtherUserProfileScreen extends ConsumerStatefulWidget {
  const OtherUserProfileScreen({
    super.key,
    required this.uid,
  });

  final String uid;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState
    extends ConsumerState<OtherUserProfileScreen> {
  final double coverHeight = 250;
  final double profileHeight = 120;

  void sendAddFriendRequest(UserModel targetUser) async {
    final result = await ref
        .watch(friendControllerProvider.notifier)
        .sendFriendRequest(targetUser);
    result.fold((l) {
      showSnackBar(context, l.message);
    }, (_) {});
  }

  void cancelFriendRequest(String requestId) async {
    final result = await ref
        .watch(friendControllerProvider.notifier)
        .cancelFriendRequest(requestId);
    result.fold((l) {
      showSnackBar(context, l.message);
    }, (_) {});
  }

  void acceptFriendRequest(UserModel targetUser) async {
    final result = await ref
        .watch(friendControllerProvider.notifier)
        .acceptFriendRequest(targetUser);
    result.fold((l) {
      showSnackBar(context, l.message);
    }, (_) {});
  }

  void unfriend(UserModel targetUser) async {
    final result =
        await ref.watch(friendControllerProvider.notifier).unfriend(targetUser);
    result.fold((l) {
      showSnackBar(context, l.message);
    }, (_) {});
  }

  void messageUser(UserModel targetUser) {
    Routemaster.of(context).push('/message/${targetUser.uid}');
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider);
    final double top = coverHeight - profileHeight / 2;
    final double bottom = profileHeight / 2;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Routemaster.of(context).pop();
          },
        ),
        title: const Text(
          'User Profile',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: ref.watch(getUserDataProvider(widget.uid)).when(
          data: (targetUser) {
            bool isFriend = currentUser!.friends.contains(targetUser.uid);
            final uids = [currentUser.uid, targetUser.uid];
            uids.sort();
            final requestId = uids.join('_');
            return ListView(
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
                        child: Image.network(
                          targetUser.bannerImage,
                          width: double.infinity,
                          height: coverHeight,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Container(
                              width: double.infinity,
                              height: coverHeight,
                              color: Colors.black,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: top,
                        child: CircleAvatar(
                          radius: profileHeight / 2,
                          backgroundColor: Colors.grey.shade800,
                          backgroundImage: CachedNetworkImageProvider(
                              targetUser.profileImage),
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
                      const Text(
                        'Short description',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Long description',
                        style: TextStyle(
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
                      const SizedBox(height: 16),
                      isFriend
                          ? _buildFriendsWidget(
                              context,
                              targetUser,
                              unfriend,
                            )
                          : ref
                              .watch(getFriendRequestStatusProvider(requestId))
                              .when(
                                data: (request) {
                                  if (request == null) {
                                    return _buildAddFriendButton(
                                      sendAddFriendRequest,
                                      targetUser,
                                    );
                                  } else if (request.requestUid ==
                                      currentUser.uid) {
                                    return _buildFriendRequestSent(
                                        cancelFriendRequest, requestId);
                                  } else {
                                    return _buildAcceptFriendRequestButton(
                                        acceptFriendRequest, targetUser);
                                  }
                                },
                                error: (error, stackTrace) =>
                                    ErrorText(error: error.toString()),
                                loading: () => const Loading(),
                              ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          messageUser(targetUser);
                        },
                        icon: const Icon(Icons.message, color: Colors.white),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 5,
                        ),
                      ).animate().fadeIn(duration: 600.ms).moveY(
                          begin: 30,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutBack),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildButton(text: 'Friends', value: 52),
                          _buildVerticalDivider(),
                          _buildButton(
                              text: 'Activity Points',
                              value: targetUser.activityPoint),
                          _buildVerticalDivider(),
                          _buildButton(
                              text: 'Achievements',
                              value: targetUser.achivements.length),
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
            );
          },
          error: (error, stackTrace) => ErrorText(error: error.toString()),
          loading: () => const Loading()),
    );
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

  Widget _buildAcceptFriendRequestButton(dynamic accept, UserModel targetUser) {
    return ElevatedButton.icon(
      onPressed: () {
        accept(targetUser);
      },
      icon: const Icon(Icons.check, color: Colors.white),
      label: const Text('Accept Friend Request'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
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

  Widget _buildButton({required String text, required int value}) {
    return MaterialButton(
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
    );
  }

  Widget _buildVerticalDivider() {
    return const VerticalDivider(
      width: 16,
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

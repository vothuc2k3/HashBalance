import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/user_profile/screen/edit_profile/edit_user_profile.dart';
import 'package:hash_balance/models/user_model.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UserProfileScreenScreenState();
}

class _UserProfileScreenScreenState extends ConsumerState<UserProfileScreen> {
  final double coverHeight = 250;
  final double profileHeight = 120;

  void navigateToEditUserProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(uid: widget.user.uid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double top = coverHeight - profileHeight / 2;
    final double bottom = profileHeight / 2;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => navigateToEditUserProfile(context),
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ],
        title: const Text(
          'User Profile',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: bottom),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  color: Colors.black,
                  child: CachedNetworkImage(
                    imageUrl: widget.user.bannerImage,
                    width: double.infinity,
                    height: coverHeight,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: top,
                  left: 10,
                  child: CircleAvatar(
                    radius: (profileHeight / 2) - 10,
                    backgroundColor: Colors.grey.shade800,
                    backgroundImage:
                        CachedNetworkImageProvider(widget.user.profileImage),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      '#${widget.user.name}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      widget.user.bio ?? 'You haven\'t said anything yet...',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      widget.user.description ??
                          'You haven\'t describe about yourself yet...',
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildSocialIcon(FontAwesomeIcons.slack),
                    const SizedBox(width: 12),
                    _buildSocialIcon(FontAwesomeIcons.github),
                    const SizedBox(width: 12),
                    _buildSocialIcon(FontAwesomeIcons.twitter),
                    const SizedBox(width: 12),
                    _buildSocialIcon(FontAwesomeIcons.linkedin),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildVerticalDivider(),
                  _buildButton(text: 'Followers', value: 0),
                  _buildVerticalDivider(),
                  _buildButton(
                      text: 'Activity Points',
                      value: widget.user.activityPoint),
                  _buildVerticalDivider(),
                  _buildButton(text: 'Achivements', value: 0),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildFriendsWidget(widget.user.uid),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return CircleAvatar(
      radius: 25,
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
            ),
          ),
        ),
      ),
    );
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
              fontSize: 10,
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
      width: 0.1,
      thickness: 1,
      color: Colors.grey,
    );
  }

  Widget _buildFriendsWidget(String uid) {
    final friendList = ref.watch(fetchFriendsProvider(uid));
    return friendList.when(
      data: (friendList) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${friendList.length} friends',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            SizedBox(
              height: 250,
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue, // Màu viền
                            width: 2.0, // Độ dày viền
                          ),
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: friend.profileImage,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('#${friend.name}',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Handle see all friends action
                },
                child: const Text('See all friends'),
              ),
            ),
          ],
        );
      },
      error: (error, stackTrace) => Center(
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

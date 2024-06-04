import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:routemaster/routemaster.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.uid,
  });

  final String uid;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UserProfileScreenScreenState();
}

class _UserProfileScreenScreenState extends ConsumerState<UserProfileScreen> {
  final double coverHeight = 250;
  final double profileHeight = 120;

  void navigateToEditUserProfile(BuildContext context) {
    Routemaster.of(context).push('/user-profile/edit/${widget.uid}');
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
      body: ref.watch(getUserDataProvider(widget.uid)).when(
          data: (user) {
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
                        color: Colors.black,
                        child: CachedNetworkImage(
                          imageUrl: user.bannerImage,
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
                              CachedNetworkImageProvider(user.profileImage),
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
                            '#${user.name}',
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
                            user.bio ?? 'You haven\'t said anything yet...',
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
                            user.description ??
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
                        _buildButton(
                            text: 'Friends', value: user.friends.length - 1),
                        _buildVerticalDivider(),
                        _buildButton(
                            text: 'Followers',
                            value: user.followers.length - 1),
                        _buildVerticalDivider(),
                        _buildButton(
                            text: 'Activity Points', value: user.activityPoint),
                        _buildVerticalDivider(),
                        _buildButton(
                            text: 'Achivements',
                            value: user.achivements.length),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    // body: ref.watch(getUserPostsProvider(widget.uid)).when(
                    //       data: (data) {
                    //         return ListView.builder(
                    //           itemCount: data.length,
                    //           itemBuilder: (BuildContext context, int index) {
                    //             final post = data[index];
                    //             return PostCard(post: post);
                    //           },
                    //         );
                    //       },
                    //       error: (error, stackTrace) {
                    //         return ErrorText(error: error.toString());
                    //       },
                    //       loading: () => const Loading(),
                    //     ),
                  ],
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
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
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

  @override
  Widget build(BuildContext context) {
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
                        color: Colors.grey,
                        child: Image.network(
                          user.bannerImage,
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
                          backgroundImage: CachedNetworkImageProvider(user.profileImage),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
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
                        const SizedBox(width: 12),
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
                            text: 'Activity Points', value: user.activityPoint),
                        _buildVerticalDivider(),
                        _buildButton(
                            text: 'Achivements',
                            value: user.achivements.length),
                        _buildVerticalDivider(),
                        _buildButton(text: 'Followers', value: 5834),
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
}
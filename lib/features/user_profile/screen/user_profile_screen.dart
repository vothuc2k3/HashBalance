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
                            text: 'Friends', value: 0),
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
                    _buildFriendsWidget(),
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

  Widget _buildFriendsWidget() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '57 friends',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  Flexible(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        'https://scontent.fsgn5-5.fna.fbcdn.net/v/t39.30808-1/414150820_1868965926854119_3491088876719626029_n.jpg?stp=c0.75.200.200a_dst-jpg_p200x200&_nc_cat=108&ccb=1-7&_nc_sid=5f2048&_nc_eui2=AeFJ0wr8a--tEaEiN8hLqfF09U4eoaR76yn1Th6hpHvrKYSUGUICtKBqpL3zf2bpnMbjoepf3ENZdWcFQVLlSkuu&_nc_ohc=dORJRds8aBoQ7kNvgFPYytz&_nc_ht=scontent.fsgn5-5.fna&oh=00_AYB47jtIoSCsCG-afxaCtjkmPIGEwtypunjqCjvwdUAvjA&oe=666F988D',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('lmaoMate', style: TextStyle(fontSize: 16)),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
            },
            child: const Text('See all friends'),
          ),
        ),
      ],
    );
  }
}

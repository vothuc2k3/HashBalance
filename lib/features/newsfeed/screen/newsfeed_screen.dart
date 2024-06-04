import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:routemaster/routemaster.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/newsfeed/controller/newsfeed_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/theme/pallette.dart';

class NewsfeedScreen extends ConsumerStatefulWidget {
  const NewsfeedScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NewsfeedScreenState();
}

class _NewsfeedScreenState extends ConsumerState<NewsfeedScreen> {
  @override
  void initState() {
    super.initState();
  }

  void navigateToCreatePostScreen() {
    Routemaster.of(context).push('/post/create');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildCreatePostContainer(user!),
          ),
          ref.watch(getCommunitiesPostsProvider).when(
                data: (posts) {
                  final hasPost = posts.isNotEmpty;
                  return !hasPost
                      ? const SliverToBoxAdapter(child: Text('NOTHING'))
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final post = posts[index];
                              return ref
                                  .watch(getUserByUidProvider(post.uid))
                                  .when(
                                    data: (user) {
                                      return _buildPostContainer(
                                          user: user, post: post);
                                    },
                                    error: (error, stackTrace) => Container(
                                      padding: const EdgeInsets.all(16),
                                      child: ErrorText(error: error.toString()),
                                    ),
                                    loading: () => const Loading(),
                                  );
                            },
                            childCount: posts.length,
                          ),
                        );
                },
                error: (error, stackTrace) => SliverToBoxAdapter(
                    child: ErrorText(error: error.toString())),
                loading: () => const SliverToBoxAdapter(child: Loading()),
              ),
        ],
      ),
    );
  }

  Widget _buildPostContainer({
    required UserModel user,
    required Post post,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.profileImage),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name),
              const Row(
                children: [
                  Text(
                    'Time post ago',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Icon(
                    Icons.public,
                    color: Colors.white,
                    size: 12,
                  )
                ],
              )
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePostContainer(UserModel user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      color: Pallete.greyColor,
      height: 125,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blueGrey,
                backgroundImage: CachedNetworkImageProvider(user.profileImage),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: navigateToCreatePostScreen,
                  child: const TextField(
                    decoration: InputDecoration(
                      labelText: 'Share your moments....',
                      labelStyle: TextStyle(
                        color: Color(0xFF38464E),
                      ),
                      enabled: false,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(
            height: 10,
            thickness: 0.5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.videocam),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Live',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      color: Pallete.redColor,
                      onPressed: () {},
                      icon: const Icon(BoxIcons.bx_git_branch),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Room',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.gamepad),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Game',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

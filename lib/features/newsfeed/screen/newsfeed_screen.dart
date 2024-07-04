// ignore_for_file: unused_result

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/newsfeed/screen/post_container/post_container.dart';
import 'package:hash_balance/features/post/screen/create_post/create_post_screen.dart';
import 'package:icons_plus/icons_plus.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/newsfeed/controller/newsfeed_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/theme/pallette.dart';

class NewsfeedScreen extends ConsumerStatefulWidget {
  const NewsfeedScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NewsfeedScreenState();
}

class _NewsfeedScreenState extends ConsumerState<NewsfeedScreen> {
  Future<void> _refreshPosts() async {
    ref.refresh(getCommunitiesPostsProvider);
  }

  void navigateToCreatePostScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: ()=>_refreshPosts(),
        child: GestureDetector(
          onTap: FocusScope.of(context).unfocus,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildCreatePostContainer(user!),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 20,
                ),
              ),
              ref.watch(getCommunitiesPostsProvider).when(
                    data: (posts) {
                      final hasPost = posts.isNotEmpty;
                      return !hasPost
                          ? const SliverToBoxAdapter(
                              child: Text(
                                'NOTHING',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final post = posts[index];

                                  return ref
                                      .watch(getUserByUidProvider(post.uid))
                                      .when(
                                          data: (user) {
                                            return ref
                                                .watch(
                                                    getCommunityByNameProvider(
                                                        post.communityName))
                                                .when(
                                                  data: (community) {
                                                    return PostContainer(
                                                      user: user,
                                                      post: post,
                                                      community: community,
                                                    );
                                                  },
                                                  error: (error, stackTrace) =>
                                                      ErrorText(
                                                          error:
                                                              error.toString()),
                                                  loading: () =>
                                                      const Loading(),
                                                );
                                          },
                                          error: (error, stackTrace) =>
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: ErrorText(
                                                    error: error.toString()),
                                              ),
                                          loading: () => const Loading());
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
        ),
      ),
    );
  }

  Widget _buildCreatePostContainer(UserModel user) {
    return InkWell(
      child: Container(
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
                  backgroundImage:
                      CachedNetworkImageProvider(user.profileImage),
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
      ),
    );
  }
}

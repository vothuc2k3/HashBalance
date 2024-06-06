import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:mdi/mdi.dart';
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

  void upvote() {}

  void downvote() {}

  Future<void> _refreshPosts() async {
    // ignore: unused_result
    ref.refresh(getCommunitiesPostsProvider);
  }

  void navigateToCreatePostScreen() {
    Routemaster.of(context).push('/post/create');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
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
                            child: Text('NOTHING'),
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
                                            .watch(getCommunityByNameProvider(
                                                post.communityName))
                                            .whenOrNull(
                                          data: (community) {
                                            return _buildPostContainer(
                                              user: user,
                                              post: post,
                                              community: community,
                                            );
                                          },
                                        );
                                      },
                                      error: (error, stackTrace) => Container(
                                        padding: const EdgeInsets.all(16),
                                        child:
                                            ErrorText(error: error.toString()),
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
      ),
    );
  }

  Widget _buildPostContainer({
    required UserModel user,
    required Post post,
    required Community community,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(community.profileImage),
                      radius: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '#=${community.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPostHeader(post, user),
                const SizedBox(height: 4),
                Text(post.content ?? ''),
                post.image != ''
                    ? const SizedBox.shrink()
                    : const SizedBox(height: 6),
              ],
            ),
          ),
          post.image != ''
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Image.network(
                    post.image!,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.error,
                        color: Color.fromARGB(255, 239, 156, 150),
                      );
                    },
                  ),
                )
              : const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildPostStat(post),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPostStat(Post post) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Pallete.greyColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward_sharp,
                size: 10,
                color: Pallete.blackColor,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                post.upvotes > 0 ? '${post.upvotes}' : '',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
            Text(
              '14 Comments',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '69 Shares',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ),
        const Divider(),
        Row(
          children: [
            _buildPostButton(
              ontap: upvote,
              icon: Icon(
                Icons.arrow_upward,
                color: Colors.grey[600],
                size: 18,
              ),
            ),
            _buildPostButton(
              ontap: downvote,
              icon: Icon(
                Icons.arrow_downward,
                color: Colors.grey[600],
                size: 18,
              ),
            ),
            _buildPostButton(
              icon: Icon(
                Icons.comment,
                color: Colors.grey[600],
                size: 18,
              ),
              ontap: () {},
            ),
            _buildPostButton(
              icon: Icon(
                Mdi.shareOutline,
                color: Colors.grey[600],
                size: 18,
              ),
              ontap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPostButton({
    required ontap,
    required Icon icon,
  }) {
    return Expanded(
      child: Material(
        color: Colors.black,
        child: InkWell(
          onTap: () {
            ontap;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 25,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [icon],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader(Post post, UserModel user) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(
            user.profileImage,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${user.name}',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              ),
              Row(
                children: [
                  Text(
                    formatTime(post.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.public,
                    color: Colors.grey,
                    size: 12,
                  ),
                ],
              )
            ],
          ),
        ),
      ],
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

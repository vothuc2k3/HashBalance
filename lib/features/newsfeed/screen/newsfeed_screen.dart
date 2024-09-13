import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/features/theme/controller/theme_controller.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/newsfeed/controller/newsfeed_controller.dart';
import 'package:hash_balance/features/newsfeed/screen/post_container/post_container.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/theme/pallette.dart';

class NewsfeedScreen extends ConsumerStatefulWidget {
  const NewsfeedScreen({
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => NewsfeedScreenState();
}

class NewsfeedScreenState extends ConsumerState<NewsfeedScreen>
    with AutomaticKeepAliveClientMixin {
  late Future<List<PostDataModel>> posts;

  Future<void> _refreshPosts() async {
    setState(() {
      posts = ref.read(newsfeedControllerProvider).getJoinedCommunitiesPosts();
    });
  }

  void _navigateToCreatePostScreen() {
    context.findAncestorStateOfType<HomeScreenState>()?.onTabTapped(2);
  }

  @override
  void initState() {
    super.initState();
    posts = ref.read(newsfeedControllerProvider).getJoinedCommunitiesPosts();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUser = ref.read(userProvider);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshPosts,
          child: GestureDetector(
            onTap: FocusScope.of(context).unfocus,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildCreatePostContainer(currentUser!),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
                SliverToBoxAdapter(
                  child: FutureBuilder<List<PostDataModel>?>(
                    future: posts,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Loading',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Loading(),
                          ].animate().fadeIn(duration: 600.ms).moveY(
                                begin: 30,
                                end: 0,
                                duration: 600.ms,
                                curve: Curves.easeOutBack,
                              ),
                        );
                      } else if (snapshot.hasError) {
                        return ErrorText(error: snapshot.error.toString());
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: SizedBox.shrink(),
                        );
                      } else if (snapshot.connectionState ==
                          ConnectionState.done) {
                        final posts = snapshot.data!;
                        return ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final postData = posts[index];
                            return PostContainer(
                              author: postData.author!,
                              post: postData.post,
                              community: postData.community,
                            ).animate().fadeIn();
                          },
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ],
            ),
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
          mainAxisAlignment: MainAxisAlignment.center,
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
                    onTap: _navigateToCreatePostScreen,
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
                  const Spacer(),
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
                  const Spacer(),
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
      ),
    );
  }
}

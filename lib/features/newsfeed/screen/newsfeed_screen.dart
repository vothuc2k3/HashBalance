import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/features/newsfeed/screen/containers/newsfeed_poll_container.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hash_balance/features/newsfeed/controller/newsfeed_controller.dart';
import 'package:hash_balance/features/newsfeed/screen/containers/newsfeed_post_container.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:icons_plus/icons_plus.dart';

class NewsfeedScreen extends ConsumerStatefulWidget {
  const NewsfeedScreen({
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => NewsfeedScreenState();
}

class NewsfeedScreenState extends ConsumerState<NewsfeedScreen>
    with AutomaticKeepAliveClientMixin {
  List<PostDataModel> loadedPosts = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshPosts() async {
    ref.invalidate(newsfeedInitPostsProvider);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    setState(() {
      _isLoadingMore = true;
    });
    final additionalPosts = await ref
        .read(newsfeedControllerProvider.notifier)
        .fetchMorePosts(loadedPosts.last.post.createdAt);

    if (additionalPosts.isNotEmpty) {
      setState(() {
        loadedPosts.addAll(additionalPosts);
      });
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _navigateToCreatePostScreen() {
    context.findAncestorStateOfType<HomeScreenState>()?.onTabTapped(2);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUser = ref.read(userProvider)!;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
        ),
        child: RefreshIndicator(
          onRefresh: _refreshPosts,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _buildCreatePostContainer(currentUser),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
              SliverToBoxAdapter(
                child: ref.watch(newsfeedInitPostsProvider).when(
                      data: (posts) {
                        loadedPosts = posts;
                        if (loadedPosts.isEmpty) {
                          return const Center(
                            child: Text(
                              'No posts available.',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: loadedPosts.length + 1,
                          itemBuilder: (context, index) {
                            if (index == loadedPosts.length) {
                              return _isLoadingMore
                                  ? const Center(child: Loading())
                                  : const SizedBox.shrink();
                            }
                            final postData = loadedPosts[index];
                            if (!postData.post.isPoll) {
                              return NewsfeedPostContainer(
                                author: postData.author!,
                                post: postData.post,
                                community: postData.community!,
                              ).animate().fadeIn();
                            } else if (postData.post.isPoll) {
                              return NewsfeedPollContainer(
                                author: postData.author!,
                                poll: postData.post,
                                community: postData.community!,
                              ).animate().fadeIn();
                            }
                            return const SizedBox.shrink();
                          },
                        );
                      },
                      loading: () => Row(
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
                      ),
                      error: (error, stackTrace) =>
                          ErrorText(error: error.toString()),
                    ),
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
        color: ref.watch(preferredThemeProvider).second,
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
                          color: Colors.white54,
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
                    color: Pallete.whiteColor,
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

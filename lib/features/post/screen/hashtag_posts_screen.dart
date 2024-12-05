import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/newsfeed/screen/containers/newsfeed_poll_container.dart';
import 'package:hash_balance/features/newsfeed/screen/containers/newsfeed_post_container.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';

class HashtagPostsScreen extends ConsumerStatefulWidget {
  final String filter;

  const HashtagPostsScreen({
    super.key,
    required this.filter,
  });

  @override
  ConsumerState<HashtagPostsScreen> createState() => _HashtagPostsScreenState();
}

class _HashtagPostsScreenState extends ConsumerState<HashtagPostsScreen> {
  List<PostDataModel> _posts = [];
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

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
        .read(postControllerProvider.notifier)
        .fetchMoreHashtagPosts(
            hashtag: widget.filter, createdAt: _posts.last.post.createdAt);

    if (additionalPosts.isNotEmpty) {
      setState(() {
        _posts.addAll(additionalPosts);
      });
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _refreshPosts() async {
    ref.invalidate(initHashtagPostsProvider(widget.filter));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _posts.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).first,
        title: Text(widget.filter),
      ),
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
                child: ref.watch(initHashtagPostsProvider(widget.filter)).when(
                      data: (posts) {
                        _posts = posts;
                        return ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _posts.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _posts.length) {
                              return _isLoadingMore
                                  ? const Center(child: Loading())
                                  : const SizedBox.shrink();
                            }
                            final postData = _posts[index];
                            if (!postData.post.isPoll) {
                              return NewsfeedPostContainer(
                                author: postData.author!,
                                post: postData.post,
                                community: postData.community!,
                              );
                            } else if (postData.post.isPoll) {
                              return NewsfeedPollContainer(
                                author: postData.author!,
                                poll: postData.post,
                                community: postData.community!,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        );
                      },
                      loading: () => const Center(child: Loading()),
                      error: (error, stackTrace) => Center(
                        child: Text('Error: $error'),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  Future<void> _refreshPosts() async {
    ref.invalidate(hashtagPostsProvider(widget.filter));
  }

  List<PostDataModel> _posts = [];

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
          child: ref.watch(hashtagPostsProvider(widget.filter)).when(
                data: (posts) {
                  _posts = posts;
                  if (_posts.isEmpty) {
                    return Center(
                      child: Text('No posts found for ${widget.filter}'),
                    );
                  }
                  return ListView.builder(
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final postData = _posts[index];
                      if (postData.post.isPoll) {
                        return NewsfeedPollContainer(
                          author: postData.author!,
                          community: postData.community!,
                          poll: postData.post,
                        );
                      }
                      return NewsfeedPostContainer(
                        post: postData.post,
                        author: postData.author!,
                        community: postData.community!,
                      );
                    },
                  );
                },
                loading: () => const Center(child: Loading()),
                error: (error, stackTrace) => Center(
                  child: Text('Error: $error'),
                ),
              ),
        ),
      ),
    );
  }
}

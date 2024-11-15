import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/widgets/plain_post_container.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';

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
        child: ref.watch(hashtagPostsProvider(widget.filter)).when(
              data: (posts) {
                if (posts.isEmpty) {
                  return Center(
                    child: Text('No posts found for ${widget.filter}'),
                  );
                }
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return PlainPostContainer(
                      post: posts[index].post,
                      author: posts[index].author!,
                      community: posts[index].community!,
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
    );
  }
}

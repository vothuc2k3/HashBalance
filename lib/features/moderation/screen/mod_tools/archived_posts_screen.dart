import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/moderation/screen/post_container/archived_post_container.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ArchivedPostScreen extends ConsumerStatefulWidget {
  final Community _community;

  const ArchivedPostScreen({
    super.key,
    required Community community,
  }) : _community = community;

  @override
  ConsumerState<ArchivedPostScreen> createState() => _ArchivedPostScreenState();
}

class _ArchivedPostScreenState extends ConsumerState<ArchivedPostScreen> {
  void _handleUnarchivePost(Post post) async {
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .unarchivePost(postId: post.id);
    result.fold(
      (l) => showToast(false, l.message),
      (r) {
        Navigator.pop(context);
        showToast(true, 'Unarchived post!');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Posts'),
        backgroundColor: ref.watch(preferredThemeProvider).second,
      ),
      body: Container(
        color: ref.watch(preferredThemeProvider).first,
        child: ref.watch(getArchivedPostsProvider(widget._community.id)).when(
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: const Text(
                      'No archived posts...',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ).animate().fadeIn(duration: 600.ms).moveY(
                          begin: 30,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                  );
                }
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return ArchivedPostContainer(
                      post: data[index].post,
                      author: data[index].author!,
                      communityId: widget._community.id,
                      unarchivePost: _handleUnarchivePost,
                    );
                  },
                );
              },
              error: (error, stack) => ErrorText(error: error.toString()),
              loading: () => const Center(child: Loading()),
            ),
      ),
    );
  }
}

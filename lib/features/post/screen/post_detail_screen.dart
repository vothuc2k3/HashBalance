import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/newsfeed/screen/containers/newsfeed_post_container.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/comment/screen/comment_container/comment_container.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final Post post;
  final UserModel author;
  final Community community;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.author,
    required this.community,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  TextEditingController commentTextController = TextEditingController();

  @override
  void dispose() {
    commentTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final community = widget.community;
    final author = widget.author;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      backgroundColor: ref.watch(preferredThemeProvider).first,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NewsfeedPostContainer(
              post: post,
              author: author,
              community: community,
            ),
            const Divider(thickness: 1, color: Colors.grey),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text(
                'Comments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[300],
                ),
              ),
            ),
            _buildCommentsSection(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildCommentInputArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Consumer(
      builder: (context, ref, child) {
        final commentsAsyncValue =
            ref.watch(getPostCommentsProvider(widget.post.id));

        return commentsAsyncValue.when(
          data: (comments) {
            if (comments == null || comments.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No comments yet. Be the first to comment!',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return CommentContainer(
                  author: comment.author,
                  comment: comment.comment,
                  post: widget.post,
                  navigateToTaggedUser: (uid) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OtherUserProfileScreen(targetUid: uid),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Loading(),
          error: (error, stackTrace) => ErrorText(error: error.toString()),
        );
      },
    );
  }

  Widget _buildCommentInputArea() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: commentTextController,
            decoration: const InputDecoration(
              hintText: 'Write a comment...',
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            onSubmitted: (text) => _addComment(),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.blueAccent),
          onPressed: _addComment,
        ),
      ],
    );
  }

  void _addComment() {
    final text = commentTextController.text.trim();
    if (text.isNotEmpty) {
      ref.read(commentControllerProvider.notifier).comment(
        widget.post,
        text,
        [],
      );
      commentTextController.clear();
    }
  }
}

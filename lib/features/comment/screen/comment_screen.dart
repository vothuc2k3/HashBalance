import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/widgets/error_text.dart';
import 'package:hash_balance/core/common/widgets/loading.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/comment/screen/comment_container/comment_container.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/post_model.dart';

class CommentScreen extends ConsumerStatefulWidget {
  final Post _post;

  const CommentScreen({
    super.key,
    required Post post,
  }) : _post = post;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CommentScreenState();
}

class _CommentScreenState extends ConsumerState<CommentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: Colors.black,
      ),
      body: ref.watch(getPostCommentsProvider(widget._post.id)).when(
            data: (comments) {
              if (comments == null) {
                return const Center(
                  child: Text(
                    'No comments available.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return ListView.builder(
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return ref.watch(getUserByUidProvider(comment.uid)).when(
                        data: (author) {
                          return CommentContainer(
                            author: author,
                            comment: comment,
                          );
                        },
                        error: (error, stackTrace) => ErrorText(
                          error: error.toString(),
                        ),
                        loading: () => const Loading(),
                      );
                },
              );
            },
            error: (error, stackTrace) => ErrorText(
              error: error.toString(),
            ),
            loading: () => const Loading(),
          ),
    );
  }
}

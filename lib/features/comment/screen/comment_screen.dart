import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/widgets/error_text.dart';
import 'package:hash_balance/core/common/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:tuple/tuple.dart';

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
  final commentTextController = TextEditingController();

  void _comment(Post post, String content) async {
    FocusScope.of(context).unfocus();
    final result = await ref
        .read(commentControllerProvider.notifier)
        .comment(post, content);
    result.fold(
      (l) {
        showToast(
          false,
          l.message,
        );
      },
      (r) {
        commentTextController.clear();
      },
    );
  }

  void _voteComment(
    Comment comment,
    Post post,
    bool userVote,
  ) async {
    final result = await ref
        .read(commentControllerProvider.notifier)
        .voteComment(comment, post, userVote);
    result.fold((l) {
      showToast(false, l.toString());
    }, (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child:
                ref.watch(getRelevantCommentsByPostProvider(widget._post)).when(
                      data: (comments) {
                        return ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            return _buildCommentWidget(
                              comment: comments[index],
                            );
                          },
                        );
                      },
                      error: (error, stackTrace) =>
                          ErrorText(error: error.toString()),
                      loading: () => const Loading(),
                    ),
          ),
          if (user != null) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                      user.profileImage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: commentTextController,
                      decoration: InputDecoration(
                        hintText: 'Leave a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (commentTextController.text.isNotEmpty) {
                        _comment(
                          widget._post,
                          commentTextController.text.trim(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildCommentWidget({
    required Comment comment,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        ref.read(getUserByUidProvider(comment.uid)).whenOrNull(
                      data: (user) {
                        return CachedNetworkImageProvider(
                          user.profileImage,
                        ) as ImageProvider;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ref
                          .watch(getUserByUidProvider(comment.uid))
                          .whenOrNull(
                        data: (user) {
                          return [
                            Text('#${user.name}',
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(comment.content == null
                                ? ''
                                : comment.content!),
                          ];
                        },
                      )!,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                children: [
                  Text(
                    formatTime(comment.createdAt),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 3),
                  _buildVoteButton(
                    icon: Icons.arrow_upward_outlined,
                    count: ref
                        .watch(
                      getCommentVoteCountProvider(
                        Tuple2(widget._post, comment),
                      ),
                    )
                        .whenOrNull(data: (count) {
                      return count['upvotes'];
                    }),
                    color: ref
                        .watch(getCommentVoteStatusProvider(
                            Tuple2(widget._post, comment)))
                        .whenOrNull(
                      data: (status) {
                        if (status == null) {
                          return Colors.grey[600];
                        } else if (status) {
                          return Colors.orange;
                        } else {
                          return Colors.grey[600];
                        }
                      },
                    ),
                    onTap: () {
                      _voteComment(comment, widget._post, true);
                    },
                  ),
                  _buildVoteButton(
                    icon: Icons.arrow_downward_outlined,
                    count: ref
                        .watch(getCommentVoteCountProvider(
                            Tuple2(widget._post, comment)))
                        .whenOrNull(data: (count) {
                      return count['downvotes'];
                    }),
                    color: ref
                        .watch(getCommentVoteStatusProvider(
                            Tuple2(widget._post, comment)))
                        .whenOrNull(
                      data: (status) {
                        if (status == null) {
                          return Colors.grey[600];
                        } else if (!status) {
                          return Colors.blue;
                        } else {
                          return Colors.grey[600];
                        }
                      },
                    ),
                    onTap: () {
                      _voteComment(comment, widget._post, false);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteButton({
    required IconData icon,
    required int? count,
    required Color? color,
    required Function onTap,
  }) {
    return InkWell(
      onTap: () => onTap(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              count == null ? '0' : count.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

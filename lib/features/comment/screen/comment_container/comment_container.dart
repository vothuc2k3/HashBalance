import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/reply_comment/controller/reply_comment_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:comment_tree/widgets/comment_tree_widget.dart';
import 'package:comment_tree/widgets/tree_theme_data.dart';

class CommentContainer extends ConsumerStatefulWidget {
  final UserModel author;
  final CommentModel comment;
  final Post post;
  final bool isReply;

  const CommentContainer({
    super.key,
    required this.author,
    required this.comment,
    required this.post,
    this.isReply = false,
  });

  @override
  ConsumerState<CommentContainer> createState() => _CommentContainerState();
}

class _CommentContainerState extends ConsumerState<CommentContainer> {
  late TextEditingController _replyController;
  UserModel? currentUser;

  void _navigateToOtherUserScreen(String currentUid) {
    if (currentUid == widget.author.uid) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(user: widget.author),
        ),
      );
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OtherUserProfileScreen(targetUser: widget.author),
          ));
    }
  }

  void _replyComment(String content) async {
    final result = await ref
        .watch(replyCommentControllerProvider.notifier)
        .reply(widget.post, widget.comment.id, content);
    result.fold((l) => showToast(false, l.message), (_) {});
  }

  void _voteComment(String commentId, bool isUpvoted) async {
    final result = await ref
        .watch(commentControllerProvider.notifier)
        .voteComment(commentId, isUpvoted);
    result.fold((l) => showToast(false, l.message), (r) {});
  }

  @override
  void initState() {
    _replyController = TextEditingController();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    currentUser = ref.watch(userProvider);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 12,
      ),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: widget.isReply ? Colors.grey[850] : Colors.black,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: CommentTreeWidget<CommentModel, CommentModel>(
        widget.comment,
        ref.watch(getCommentRepliesProvider(widget.comment.id)).when(
              data: (replies) {
                return replies ?? [];
              },
              error: (e, s) => [],
              loading: () => [],
            ),
        treeThemeData: const TreeThemeData(
          lineColor: Colors.green,
          lineWidth: 2,
        ),
        avatarRoot: (context, data) => PreferredSize(
          preferredSize: const Size.fromRadius(18),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey,
            backgroundImage:
                CachedNetworkImageProvider(widget.author.profileImage),
          ),
        ),
        avatarChild: (context, data) => PreferredSize(
          preferredSize: const Size.fromRadius(12),
          child: CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey,
            backgroundImage:
                CachedNetworkImageProvider(widget.author.profileImage),
          ),
        ),
        contentRoot: (context, data) =>
            _buildContent(widget.author, widget.comment),
        contentChild: (context, data) =>
            ref.watch(getUserByUidProvider(data.uid)).when(
                  data: (replyAuthor) {
                    return _buildContent(replyAuthor, data);
                  },
                  error: (e, s) => ErrorText(error: e.toString()),
                  loading: () => const Loading(),
                ),
      ),
    );
  }

  Widget _buildContent(UserModel author, CommentModel comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _navigateToOtherUserScreen(currentUser!.uid),
            child: Text(
              '#${author.name}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                formatTime(comment.createdAt),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.public,
                color: Colors.grey,
                size: 12,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment.content!,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Upvote button
              ref.read(getCommentVoteStatusProvider(comment.id)).when(
                    data: (isUpvoted) {
                      return IconButton(
                        icon: Icon(
                          Icons.arrow_upward,
                          color:
                              isUpvoted == true ? Colors.green : Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          _voteComment(comment.id, true);
                        },
                      );
                    },
                    error: (e, s) => const IconButton(
                      icon: Icon(Icons.arrow_upward,
                          color: Colors.white, size: 20),
                      onPressed: null,
                    ),
                    loading: () => const CircularProgressIndicator(),
                  ),
              // Upvote count
              ref.read(getCommentVoteCountProvider(comment.id)).when(
                    data: (voteCounts) {
                      return Text(
                        voteCounts['upvotes'].toString(),
                        style: const TextStyle(color: Colors.white),
                      );
                    },
                    error: (e, s) =>
                        const Text('0', style: TextStyle(color: Colors.white)),
                    loading: () => const CircularProgressIndicator(),
                  ),
              const SizedBox(width: 10),
              // Downvote button
              ref.read(getCommentVoteStatusProvider(comment.id)).when(
                    data: (isUpvoted) {
                      return IconButton(
                        icon: Icon(
                          Icons.arrow_downward,
                          color: isUpvoted == false ? Colors.red : Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          _voteComment(comment.id, false);
                        },
                      );
                    },
                    error: (e, s) => const IconButton(
                      icon: Icon(Icons.arrow_downward,
                          color: Colors.white, size: 20),
                      onPressed: null,
                    ),
                    loading: () => const CircularProgressIndicator(),
                  ),
              // Downvote count
              ref.read(getCommentVoteCountProvider(comment.id)).when(
                    data: (voteCounts) {
                      return Text(
                        voteCounts['downvotes'].toString(),
                        style: const TextStyle(color: Colors.white),
                      );
                    },
                    error: (e, s) =>
                        const Text('0', style: TextStyle(color: Colors.white)),
                    loading: () => const CircularProgressIndicator(),
                  ),
            ],
          ),
          const SizedBox(height: 4),
          CommentActions(
            onReply: () => _showReplyDialog(),
          ),
        ],
      ),
    );
  }

  void _showReplyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reply to Comment'),
          content: TextField(
            controller: _replyController,
            decoration: const InputDecoration(
              hintText: 'Type your reply...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_replyController.text.isNotEmpty) {
                  _replyComment(_replyController.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Reply'),
            ),
          ],
        );
      },
    );
  }
}

class CommentActions extends ConsumerWidget {
  final Function _onReply;

  const CommentActions({
    super.key,
    required Function onReply,
  }) : _onReply = onReply;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(
            Icons.reply,
            color: Colors.white,
          ),
          onPressed: () => _onReply(),
        ),
      ],
    );
  }
}

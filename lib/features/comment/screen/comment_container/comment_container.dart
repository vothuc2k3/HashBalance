import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mdi/mdi.dart';

import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/user_model.dart';

class CommentContainer extends ConsumerStatefulWidget {
  final UserModel author;
  final Comment comment;

  const CommentContainer({
    super.key,
    required this.author,
    required this.comment,
  });

  @override
  ConsumerState<CommentContainer> createState() => _CommentContainerState();
}

class _CommentContainerState extends ConsumerState<CommentContainer> {
  TextEditingController commentTextController = TextEditingController();
  UserModel? currentUser;

  void _voteComment(bool userVote) async {
    final result = await ref
        .watch(commentControllerProvider.notifier)
        .voteComment(widget.comment, userVote);
    result.fold((l) {
      showToast(false, l.toString());
    }, (_) {});
  }

  void _navigateToOtherUserScreen(String currentUid) {
    switch (currentUid == widget.author.uid) {
      case true:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(
              user: widget.author,
            ),
          ),
        );
        break;
      case false:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtherUserProfileScreen(
              targetUser: widget.author,
            ),
          ),
        );
        break;
    }
  }

  @override
  void didChangeDependencies() {
    currentUser = ref.watch(userProvider);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPostHeader(widget.comment, widget.author),
                const SizedBox(height: 4),
                Text(widget.comment.content!),
                const SizedBox(height: 8),
                CommentActions(
                  comment: widget.comment,
                  onVote: _voteComment,
                  onReply: () => _showReplyDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostHeader(
    Comment post,
    UserModel author,
  ) {
    return Row(
      children: [
        InkWell(
          onTap: () => _navigateToOtherUserScreen(currentUser!.uid),
          child: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(
              author.profileImage,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${author.name}',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              ),
              Row(
                children: [
                  Text(
                    formatTime(post.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.public,
                    color: Colors.grey,
                    size: 12,
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  void _showReplyDialog(BuildContext context) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reply to Comment'),
          content: TextField(
            controller: replyController,
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
                if (replyController.text.isNotEmpty) {
                  //TODO: REPLY HERE
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
  final Comment _comment;
  final Function _onVote;
  final Function _onReply;

  const CommentActions({
    super.key,
    required Comment comment,
    required Function onVote,
    required Function onReply,
  })  : _comment = comment,
        _onVote = onVote,
        _onReply = onReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildVoteButton(
          icon: Icons.arrow_upward_rounded,
          count: ref.watch(getCommentVoteCountProvider(_comment.id)).whenOrNull(
              data: (count) {
            return count['upvotes'];
          }),
          color:
              ref.watch(getCommentVoteStatusProvider(_comment.id)).whenOrNull(
            data: (status) {
              switch (status) {
                case true:
                  return Colors.orange;
                case false:
                  return Colors.grey[600];
                case null:
                  return Colors.grey[600];
              }
            },
          ),
          onTap: () => _onVote(true),
        ),
        _buildVoteButton(
          icon: Mdi.arrowDown,
          count: ref.watch(getCommentVoteCountProvider(_comment.id)).whenOrNull(
              data: (count) {
            return count['downvotes'];
          }),
          color: ref
              .watch(getCommentVoteStatusProvider(_comment.id))
              .whenOrNull(data: (status) {
            switch (status) {
              case true:
                return Colors.grey[600];
              case false:
                return Colors.blue;
              case null:
                return Colors.grey[600];
            }
          }),
          onTap: () => _onVote(false),
        ),
        IconButton(
          icon: const Icon(Icons.reply, color: Colors.white),
          onPressed: () => _onReply(),
        ),
      ],
    );
  }

  Widget _buildVoteButton({
    required IconData icon,
    required int? count,
    required Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/vote_button.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:mdi/mdi.dart';

class PostActions extends ConsumerStatefulWidget {
  final Post post;
  final Function onVote;
  final Function onComment;
  final Function onShare;

  const PostActions(
      {super.key,
      required this.post,
      required this.onVote,
      required this.onComment,
      required this.onShare});

  @override
  ConsumerState<PostActions> createState() => _PostActionsState();
}

class _PostActionsState extends ConsumerState<PostActions> {
  Map<String, dynamic>? previousData;

  @override
  Widget build(BuildContext context) {
    final asyncValue =
        ref.watch(getPostVoteCountAndStatusStreamProvider(widget.post));

    return asyncValue.when(
      data: (data) {
        previousData = data;
        final upvotes = data['upvotes'] ?? 0;
        final downvotes = data['downvotes'] ?? 0;
        final status = data['userVoteStatus'];
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            VoteButton(
              icon: Icons.arrow_upward_rounded,
              count: upvotes,
              color: status == 'upvoted' ? Colors.orange : Colors.grey[600],
              onTap: (isUpvote) => widget.onVote(isUpvote),
              isUpvote: true,
            ),
            VoteButton(
              icon: Mdi.arrowDown,
              count: downvotes,
              color: status == 'downvoted' ? Colors.blue : Colors.grey[600],
              onTap: (isUpvote) => widget.onVote(isUpvote),
              isUpvote: false,
            ),
            _buildActionButton(
              icon: Mdi.commentOutline,
              label: 'Comments',
              onTap: widget.onComment,
            ),
            _buildActionButton(
              icon: Mdi.shareOutline,
              label: 'Share',
              onTap: widget.onShare,
            ),
          ],
        );
      },
      loading: () {
        if (previousData != null) {
          final upvotes = previousData!['upvotes'] ?? 0;
          final downvotes = previousData!['downvotes'] ?? 0;
          final status = previousData!['userVoteStatus'];
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              VoteButton(
                icon: Icons.arrow_upward_rounded,
                count: upvotes,
                color: status == 'upvoted' ? Colors.orange : Colors.grey[600],
                onTap: (isUpvote) => widget.onVote(isUpvote),
                isUpvote: true,
              ),
              VoteButton(
                icon: Mdi.arrowDown,
                count: downvotes,
                color: status == 'downvoted' ? Colors.blue : Colors.grey[600],
                onTap: (isUpvote) => widget.onVote(isUpvote),
                isUpvote: false,
              ),
              _buildActionButton(
                icon: Mdi.commentOutline,
                label: 'Comments',
                onTap: widget.onComment,
              ),
              _buildActionButton(
                icon: Mdi.shareOutline,
                label: 'Share',
                onTap: widget.onShare,
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
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
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
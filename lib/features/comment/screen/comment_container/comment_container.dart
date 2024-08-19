import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/widgets/error_text.dart';
import 'package:hash_balance/core/common/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/reply_comment/controller/reply_comment_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:comment_tree/data/comment.dart';
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
  late TextEditingController _commentController;
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

  @override
  void initState() {
    _commentController = TextEditingController();
    _replyController = TextEditingController();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    currentUser = ref.watch(userProvider);
    super.didChangeDependencies();
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
                return replies ??
                    []; // Trả về một danh sách trống nếu replies là null
              },
              error: (e, s) => [], // Trả về một danh sách trống khi có lỗi
              loading: () => [], // Trả về một danh sách trống khi đang tải
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            comment.content!,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          CommentActions(
            comment: comment,
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
  final CommentModel _comment;
  final Function _onReply;

  const CommentActions({
    super.key,
    required CommentModel comment,
    required Function onReply,
  })  : _comment = comment,
        _onReply = onReply;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.reply, color: Colors.white),
          onPressed: () => _onReply(),
        ),
      ],
    );
  }
}

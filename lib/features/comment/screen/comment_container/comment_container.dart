import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/reply_comment/controller/reply_comment_controller.dart';
import 'package:hash_balance/features/report/controller/report_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/features/vote_comment/controller/vote_comment_controller.dart';
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
  final Function(String) navigateToTaggedUser;

  const CommentContainer({
    super.key,
    required this.author,
    required this.comment,
    required this.post,
    this.isReply = false,
    required this.navigateToTaggedUser,
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
          builder: (context) => const UserProfileScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OtherUserProfileScreen(targetUid: widget.author.uid),
        ),
      );
    }
  }

  void _replyComment(String content) async {
    final result = await ref
        .watch(replyCommentControllerProvider.notifier)
        .reply(widget.post, widget.comment.id, content);
    result.fold((l) => showToast(false, l.message), (_) {});
  }

  void _voteComment(String commentId, bool userVote) async {
    switch (userVote) {
      case true:
        final result = await ref
            .read(upvoteCommentControllerProvider.notifier)
            .voteComment(commentId);
        result.fold((l) {
          showToast(false, l.toString());
        }, (_) {});
        break;
      case false:
        final result = await ref
            .read(downvoteCommentControllerProvider.notifier)
            .voteComment(commentId);
        result.fold((l) {
          showToast(false, l.toString());
        }, (_) {});
        break;
    }
  }

  void _handleReportComment(CommentModel comment) async {
    TextEditingController reportReasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text('Report Comment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter the reason for reporting this comment:'),
              const SizedBox(height: 8),
              TextField(
                controller: reportReasonController,
                decoration: const InputDecoration(
                  hintText: 'Reason',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.greenAccent,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final reason = reportReasonController.text;
                if (reason.isNotEmpty) {
                  Navigator.of(context).pop();
                  final result =
                      await ref.read(reportControllerProvider).addReport(
                            null,
                            widget.comment.id,
                            null,
                            Constants.commentReportType,
                            widget.post.communityId,
                            reason,
                          );
                  result.fold(
                    (l) => showToast(false, l.message),
                    (_) => showToast(true, 'Report submitted successfully'),
                  );
                } else {
                  showToast(false, 'Please enter a reason for reporting');
                }
              },
              child: const Text(
                'Submit',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleDeleteComment(CommentModel comment) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this comment?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.greenAccent,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await ref
                    .read(commentControllerProvider.notifier)
                    .deleteComment(comment.id);
                result.fold(
                  (l) => showToast(false, l.message),
                  (_) {},
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(CommentModel comment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Comment'),
          content: TextField(
            controller: TextEditingController(text: comment.content),
            decoration: const InputDecoration(
              hintText: 'Edit your comment...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: ref.watch(preferredThemeProvider).second,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_replyController.text.isNotEmpty) {
                  _replyComment(_replyController.text);
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ref.watch(preferredThemeProvider).second,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
    int repliesCount = 0;
    final themeColor = ref.watch(preferredThemeProvider);

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 12,
      ),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: themeColor.second,
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
                repliesCount = replies == null ? 0 : replies.length;
                return replies ?? [];
              },
              error: (e, s) => [],
              loading: () => [],
            ),
        treeThemeData: TreeThemeData(
          lineWidth: (repliesCount > 0) ? 2 : 0,
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
        contentRoot: (context, data) => ref
            .watch(
              userRoleProvider(
                getMembershipId(
                  uid: currentUser!.uid,
                  communityId: widget.post.communityId,
                ),
              ),
            )
            .when(
              data: (communityRole) =>
                  _buildContent(widget.author, widget.comment, communityRole),
              error: (e, s) => ErrorText(error: e.toString()),
              loading: () => const Loading(),
            ),
        contentChild: (context, data) =>
            ref.watch(getUserDataProvider(data.uid)).when(
                  data: (replyAuthor) => ref
                      .read(
                        userRoleProvider(
                          getMembershipId(
                            uid: currentUser!.uid,
                            communityId: widget.post.communityId,
                          ),
                        ),
                      )
                      .when(
                        data: (communityRole) =>
                            _buildContent(replyAuthor, data, communityRole),
                        error: (e, s) => ErrorText(error: e.toString()),
                        loading: () => const Loading(),
                      ),
                  error: (e, s) => ErrorText(error: e.toString()),
                  loading: () => const Loading(),
                ),
      ),
    );
  }

  Widget _buildContent(
    UserModel author,
    CommentModel comment,
    String role,
  ) {
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
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditDialog(comment);
                      break;
                    case 'delete':
                      _handleDeleteComment(comment);
                      break;
                    case 'view_profile':
                      _navigateToOtherUserScreen(ref.read(userProvider)!.uid);
                      break;
                    case 'report':
                      _handleReportComment(comment);
                      break;
                    case 'cancel':
                      Navigator.of(context).pop();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    if (currentUser!.uid == comment.uid)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                    if (currentUser!.uid == comment.uid || role == 'moderator')
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    if (currentUser!.uid != comment.uid)
                      PopupMenuItem(
                        value: 'view_profile',
                        child: Text('View ${widget.author.name} Profile'),
                      ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Text('Report'),
                    ),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Text('Cancel'),
                    ),
                  ];
                },
                icon: const Icon(
                  Icons.more_horiz,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildCommentContent(comment),
          const SizedBox(height: 8),
          Row(
            children: [
              // Upvote button
              ref.watch(getCommentVoteStatusProvider(comment.id)).when(
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
                    loading: () => const SizedBox(),
                  ),
              // Upvote count
              ref.watch(getCommentVoteCountProvider(comment.id)).when(
                    data: (voteCounts) {
                      return Text(
                        voteCounts['upvotes'].toString(),
                        style: const TextStyle(color: Colors.white),
                      );
                    },
                    error: (e, s) =>
                        const Text('0', style: TextStyle(color: Colors.white)),
                    loading: () => const SizedBox(),
                  ),
              const SizedBox(width: 10),
              ref.watch(getCommentVoteStatusProvider(comment.id)).when(
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
                    loading: () => const SizedBox(),
                  ),
              // Downvote count
              ref.watch(getCommentVoteCountProvider(comment.id)).when(
                    data: (voteCounts) {
                      return Text(
                        voteCounts['downvotes'].toString(),
                        style: const TextStyle(color: Colors.white),
                      );
                    },
                    error: (e, s) =>
                        const Text('0', style: TextStyle(color: Colors.white)),
                    loading: () => const SizedBox(),
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

  Widget _buildCommentContent(CommentModel comment) {
    List<TextSpan> spans = [];
    final RegExp hashtagRegExp = RegExp(r'\B#\w\w+');

    comment.content!.splitMapJoin(
      hashtagRegExp,
      onMatch: (Match match) {
        String? hashtag = match.group(0);
        if (hashtag != null && hashtag.startsWith('#')) {
          String taggedName = hashtag.substring(1);
          String? taggedUid = comment.mentionedUser!.entries
              .firstWhere(
                (entry) => entry.value == taggedName,
                orElse: () => const MapEntry('', ''),
              )
              .key;
          if (taggedUid.isNotEmpty) {
            spans.add(
              TextSpan(
                text: hashtag,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    widget.navigateToTaggedUser(taggedUid);
                  },
              ),
            );
          } else {
            spans.add(
              TextSpan(
                text: hashtag,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }
        }
        return '';
      },
      onNonMatch: (String nonMatch) {
        spans.add(TextSpan(
          text: nonMatch,
          style: const TextStyle(fontSize: 14),
        ));
        return '';
      },
    );

    return RichText(
      text: TextSpan(
        children: spans,
        style: const TextStyle(fontSize: 14),
      ),
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

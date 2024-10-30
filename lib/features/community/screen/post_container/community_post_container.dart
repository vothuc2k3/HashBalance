import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/widgets/post_actions.dart';
import 'package:hash_balance/core/widgets/post_header_widget.dart';
import 'package:hash_balance/core/widgets/post_images_grid.dart';
import 'package:hash_balance/core/widgets/video_player_widget.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/post_share/controller/post_share_controller.dart';
import 'package:hash_balance/features/report/controller/report_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/features/vote_post/controller/vote_post_controller.dart';

import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/comment/screen/comment_screen.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/features/post/screen/edit_post_screen.dart';

class PostContainer extends ConsumerStatefulWidget {
  final bool isMod;
  final UserModel author;
  final Post post;
  final String communityId;
  final String communityName;
  final bool isPinnedPost;
  final Function(Post)? onPinPost;
  final Function(Post)? onUnPinPost;

  const PostContainer({
    super.key,
    required this.isMod,
    required this.author,
    required this.post,
    required this.communityId,
    required this.communityName,
    required this.isPinnedPost,
    this.onPinPost,
    this.onUnPinPost,
  });

  @override
  ConsumerState<PostContainer> createState() => _PostContainerState();
}

class _PostContainerState extends ConsumerState<PostContainer> {
  TextEditingController commentTextController = TextEditingController();
  TextEditingController shareTextController = TextEditingController();

  void _handleEditPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostScreen(
          post: widget.post,
        ),
      ),
    );
  }

  void _archivePost(String postId) async {
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .archivePost(postId: postId);
    result.fold((l) => showToast(false, l.message), (r) {
      showToast(true, 'Post archived successfully...');
    });
  }

  void _handleArchivePost(String postId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).second,
          title: const Text('Archive Post'),
          content: const Text(
              'Archiving will hide this post out of newsfeed, are you sure?'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.greenAccent,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                _archivePost(postId);
                Navigator.of(context).pop();
              },
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );
  }

  void _votePost(bool userVote) async {
    switch (userVote) {
      case true:
        final result =
            await ref.read(upvotePostControllerProvider.notifier).votePost(
                  post: widget.post,
                  postAuthorName: widget.author.name,
                  communityName: widget.communityName,
                );
        result.fold((l) {
          showToast(false, l.toString());
        }, (_) {});
        break;
      case false:
        final result =
            await ref.read(downvotePostControllerProvider.notifier).votePost(
                  post: widget.post,
                  postAuthorName: widget.author.name,
                  communityName: widget.communityName,
                );
        result.fold((l) {
          showToast(false, l.toString());
        }, (_) {});
        break;
    }
  }

  void _sharePost(String? content) async {
    final result = await ref
        .watch(postShareControllerProvider.notifier)
        .sharePost(postId: widget.post.id, content: content);
    result.fold((l) => showToast(false, l.message), (r) {
      showToast(true, 'Share successfully...');
    });
  }

  void _handleDeletePost(Post post) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmDelete == true) {
      final result =
          await ref.read(postControllerProvider.notifier).deletePost(post);
      result.fold((l) => showToast(false, l.message), (r) {
        showToast(true, 'Post deleted successfully...');
      });
    }
  }

  void _navigateToCommentScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(
          post: widget.post,
        ),
      ),
    );
  }

  void _navigateToOtherUserScreen(String currentUid) {
    switch (currentUid == widget.author.uid) {
      case true:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UserProfileScreen(),
          ),
        );
        break;
      case false:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OtherUserProfileScreen(targetUid: widget.author.uid),
          ),
        );
        break;
    }
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Share Post'),
          content: TextField(
            controller: shareTextController,
            decoration: const InputDecoration(
              hintText: 'Add a message to your share...',
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
                if (shareTextController.text.isNotEmpty) {
                  _sharePost(shareTextController.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  void _handleReportPost() {
    TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter the reason for reporting this post:'),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter your reason here',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text;
                if (reason.isNotEmpty) {
                  _submitReportPost(reason);
                  Navigator.of(context).pop();
                } else {
                  showToast(false, 'Please provide a reason for reporting.');
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _submitReportPost(String reason) async {
    final result = await ref.read(reportControllerProvider).addReport(
          widget.post.id,
          null,
          null,
          Constants.postReportType,
          widget.communityId,
          reason,
        );
    result.fold((l) => showToast(false, l.message), (r) {
      showToast(true, 'Your report has been recorded!');
    });
  }

  void _showPostOptionsMenu(String currentUid, String postUsername) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (!widget.post.isPoll && widget.post.uid == currentUid)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit post'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleEditPost();
                  },
                ),
              if (widget.isMod && !widget.isPinnedPost)
                ListTile(
                  leading: const Icon(Icons.person_remove),
                  title: const Text('Pin this post'),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (widget.onPinPost != null) {
                      widget.onPinPost!(widget.post);
                    }
                  },
                ),
              if (widget.isMod && widget.isPinnedPost)
                ListTile(
                  leading: const Icon(Icons.person_remove),
                  title: const Text('Unpin this post'),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (widget.onUnPinPost != null) {
                      widget.onUnPinPost!(widget.post);
                    }
                  },
                ),
              if (currentUid == widget.post.uid || widget.isMod)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleDeletePost(widget.post);
                  },
                ),
              if (widget.isMod)
                ListTile(
                  leading: const Icon(Icons.archive),
                  title: const Text('Archive'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleArchivePost(widget.post.id);
                  },
                ),
              if (!widget.isMod || currentUid != widget.post.uid)
                ListTile(
                  leading: const Icon(Icons.warning),
                  title: const Text('Report this post'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleReportPost();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.read(userProvider);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: widget.isPinnedPost
            ? const Color(0xFF181C30)
            : ref.watch(preferredThemeProvider).second,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: widget.isPinnedPost ? Colors.orangeAccent : Colors.white,
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                PostHeaderWidget.author(
                  author: widget.author,
                  createdAt: widget.post.createdAt,
                  onAuthorTap: () =>
                      _navigateToOtherUserScreen(widget.author.uid),
                  onOptionsTap: () => _showPostOptionsMenu(
                    currentUser!.uid,
                    widget.author.name,
                  ),
                ),
                const SizedBox(height: 4),
                Text(widget.post.content),
                widget.post.images != null && widget.post.images!.isNotEmpty
                    ? const SizedBox.shrink()
                    : const SizedBox(height: 6),
              ],
            ),
          ),
          widget.post.images != null && widget.post.images!.isNotEmpty
              ? PostImagesGrid(images: widget.post.images!)
              : const SizedBox.shrink(),
          widget.post.video != null && widget.post.video != ''
              ? VideoPlayerWidget(videoUrl: widget.post.video!)
              : const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildPostStat(
              user: widget.author,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostStat({required UserModel user}) {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 4),
            const Expanded(
              child: Text(''),
            ),
            FutureBuilder<int>(
              future: ref
                  .read(postControllerProvider.notifier)
                  .getPostCommentCount(widget.post.id),
              builder: (context, snapshot) {
                return InkWell(
                  onTap: () => _navigateToCommentScreen(),
                  child: Text(
                    '${snapshot.data} Comments',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            FutureBuilder<int>(
              future: ref
                  .read(postControllerProvider.notifier)
                  .getPostShareCount(widget.post.id),
              builder: (context, snapshot) {
                return InkWell(
                  onTap: () => _navigateToCommentScreen(),
                  child: Text(
                    '${snapshot.data} Shares',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const Divider(
          thickness: 0.5,
          indent: 5,
        ),
        PostActions(
          post: widget.post,
          onVote: _votePost,
          onComment: () {
            _navigateToCommentScreen();
          },
          onShare: _showShareDialog,
        ),
        const Divider(
          thickness: 0.5,
          indent: 5,
        ),
      ],
    );
  }
}

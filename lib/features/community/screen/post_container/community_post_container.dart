import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/widgets/post_images_grid.dart';
import 'package:hash_balance/core/widgets/post_static_button.dart';
import 'package:hash_balance/core/widgets/video_player_widget.dart';
import 'package:hash_balance/core/widgets/vote_button.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/post/screen/hashtag_posts_screen.dart';
import 'package:hash_balance/features/post_share/screen/post_share_screen.dart';
import 'package:hash_balance/features/report/controller/report_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/features/vote_post/controller/vote_post_controller.dart';

import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/comment/screen/comment_screen.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/features/post/screen/edit_post_screen.dart';

class CommunityPostContainer extends ConsumerStatefulWidget {
  final bool isMod;
  final UserModel author;
  final Post post;
  final Community community;
  final bool isPinnedPost;
  final Function(Post)? onPinPost;
  final Function(Post)? onUnPinPost;

  const CommunityPostContainer({
    super.key,
    required this.isMod,
    required this.author,
    required this.post,
    required this.community,
    required this.isPinnedPost,
    this.onPinPost,
    this.onUnPinPost,
  });

  @override
  ConsumerState<CommunityPostContainer> createState() =>
      _CommunityPostContainerState();
}

class _CommunityPostContainerState
    extends ConsumerState<CommunityPostContainer> {
  late Stream<Map<String, dynamic>> _postVoteCountAndStatus;
  TextEditingController commentTextController = TextEditingController();
  TextEditingController shareTextController = TextEditingController();

  void _navigateToHashtagPostsScreen(String hashtag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HashtagPostsScreen(filter: hashtag),
      ),
    );
  }

  void _navigateToPostShareScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostShareScreen(
          post: widget.post,
          author: widget.author,
          community: widget.community,
        ),
      ),
    );
  }

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
                  communityName: widget.community.name,
                );
        result.fold((l) {
          showToast(false, l.toString());
        }, (_) {
          setState(() {});
          _postVoteCountAndStatus = ref
              .read(postControllerProvider.notifier)
              .getPostVoteCountAndStatus(widget.post);
        });
        break;
      case false:
        final result =
            await ref.read(downvotePostControllerProvider.notifier).votePost(
                  post: widget.post,
                  postAuthorName: widget.author.name,
                  communityName: widget.community.name,
                );
        result.fold((l) {
          showToast(false, l.toString());
        }, (_) {
          setState(() {});
          _postVoteCountAndStatus = ref
              .read(postControllerProvider.notifier)
              .getPostVoteCountAndStatus(widget.post);
        });
        break;
    }
  }

  void _handleDeletePost(Post post) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.greenAccent,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
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
          postAuthorName: widget.author.name,
          communityName: widget.community.name,
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
          widget.community.id,
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
          child: Container(
            color: ref.watch(preferredThemeProvider).second,
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
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _postVoteCountAndStatus = ref
        .read(postControllerProvider.notifier)
        .getPostVoteCountAndStatus(widget.post);
  }

  @override
  Widget build(BuildContext context) {
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
                _buildPostHeader(widget.post, widget.author),
                const SizedBox(height: 4),
                _buildContentWithHashtags(widget.post.content),
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

  Widget _buildPostHeader(
    Post post,
    UserModel author,
  ) {
    final currentUser = ref.watch(userProvider)!;
    return Row(
      children: [
        InkWell(
          onTap: () => _navigateToOtherUserScreen(currentUser.uid),
          child: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(author.profileImage),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author.name,
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
        IconButton(
          onPressed: () {
            _showPostOptionsMenu(currentUser.uid, widget.author.name);
          },
          icon: const Icon(Icons.more_horiz),
        ),
      ],
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
          onVote: _votePost,
          onComment: () {
            _navigateToCommentScreen();
          },
          onShare: _navigateToPostShareScreen,
          postVoteCountAndStatus: _postVoteCountAndStatus,
        ),
        const Divider(
          thickness: 0.5,
          indent: 5,
        ),
      ],
    );
  }

  Widget _buildContentWithHashtags(String content) {
    final hashtagRegExp = RegExp(r'#[a-zA-Z0-9_]+');
    final matches = hashtagRegExp.allMatches(content);

    if (matches.isEmpty) {
      return Text(content);
    }

    List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (var match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: content.substring(lastMatchEnd, match.start),
            style: DefaultTextStyle.of(context).style,
          ),
        );
      }
      spans.add(TextSpan(
        text: content.substring(match.start, match.end),
        style: DefaultTextStyle.of(context).style.copyWith(color: Colors.blue),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _navigateToHashtagPostsScreen(
                content.substring(match.start, match.end),
              ),
      ));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastMatchEnd),
        style: DefaultTextStyle.of(context).style,
      ));
    }
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

class PostActions extends ConsumerWidget {
  final Function _onVote;
  final Function _onComment;
  final Function _onShare;
  final Stream<Map<String, dynamic>> _postVoteCountAndStatus;

  const PostActions({
    super.key,
    required Function(bool) onVote,
    required Function onComment,
    required Function onShare,
    required Stream<Map<String, dynamic>> postVoteCountAndStatus,
  })  : _onVote = onVote,
        _onComment = onComment,
        _onShare = onShare,
        _postVoteCountAndStatus = postVoteCountAndStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _postVoteCountAndStatus,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
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
                onTap: (isUpvote) => _onVote(isUpvote),
                isUpvote: true,
              ),
              VoteButton(
                icon: Icons.arrow_downward_rounded,
                count: downvotes,
                color: status == 'downvoted' ? Colors.blue : Colors.grey[600],
                onTap: (isUpvote) => _onVote(isUpvote),
                isUpvote: false,
              ),
              PostStaticButton(
                icon: Icons.comment_rounded,
                onTap: _onComment,
              ),
              PostStaticButton(
                icon: Icons.share_rounded,
                onTap: _onShare,
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

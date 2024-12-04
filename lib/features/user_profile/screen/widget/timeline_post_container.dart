import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';
import 'package:hash_balance/core/widgets/post_images_grid.dart';
import 'package:hash_balance/core/widgets/post_static_button.dart';
import 'package:hash_balance/core/widgets/video_player_widget.dart';
import 'package:hash_balance/core/widgets/vote_button.dart';
import 'package:hash_balance/features/community/controller/community_controller.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/newsfeed/controller/newsfeed_controller.dart';
import 'package:hash_balance/features/post_share/screen/post_share_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/vote_post/controller/vote_post_controller.dart';
import 'package:mdi/mdi.dart';

import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/comment/screen/comment_screen.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

class TimelinePostContainer extends ConsumerStatefulWidget {
  final UserModel author;
  final Post post;
  final Community community;

  const TimelinePostContainer({
    super.key,
    required this.author,
    required this.post,
    required this.community,
  });

  @override
  ConsumerState<TimelinePostContainer> createState() =>
      _TimelinePostContainerState();
}

class _TimelinePostContainerState extends ConsumerState<TimelinePostContainer> {
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
          ref
              .refresh(postControllerProvider.notifier)
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
          ref
              .refresh(postControllerProvider.notifier)
              .getPostVoteCountAndStatus(widget.post);
        });
        break;
    }
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

  void _handleDeletePost(Post post) async {
    final result =
        await ref.read(postControllerProvider.notifier).deletePost(post);
    result.fold(
      (l) {
        showToast(false, l.message);
      },
      (r) {
        showToast(true, 'Delete successfully...');
        ref.invalidate(newsfeedInitPostsProvider);
      },
    );
  }

  void _showPostOptionsMenu(String currentUid, String postUsername) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (currentUid == widget.post.uid)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete this post'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleDeletePost(widget.post);
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

  void _navigateToCommunityScreen(
    Community community,
    String uid,
  ) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
    final result = await ref
        .read(communityControllerProvider.notifier)
        .fetchSuspendStatus(communityId: community.id, uid: uid);
    result.fold(
      (l) {
        showToast(false, 'Unexpected error happened...');
      },
      (r) {
        if (r) {
          showToast(false, 'You are suspended from this community');
          Navigator.pop(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityScreen(
                communityId: community.id,
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(5),
      color: ref.watch(preferredThemeProvider).second,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPostHeader(widget.author),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildContentWithHashtags(widget.post.content),
                widget.post.images != null && widget.post.video == ''
                    ? const SizedBox(height: 6)
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          if (widget.post.images != null && widget.post.images!.isNotEmpty)
            PostImagesGrid(images: widget.post.images!),
          if (widget.post.video != null && widget.post.video!.isNotEmpty)
            VideoPlayerWidget(videoUrl: widget.post.video!),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildPostStat(),
          ),
        ],
      ),
    );
  }

  Widget _buildPostHeader(UserModel currentUser) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  _navigateToCommunityScreen(
                    widget.community,
                    currentUser.uid,
                  );
                },
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                    widget.community.profileImage,
                  ),
                  radius: 20,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.community.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatTime(
                      widget.post.createdAt,
                    ),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
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

  Widget _buildPostStat() {
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
          onShare: _navigateToPostShareScreen,
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
        spans.add(TextSpan(
          text: content.substring(lastMatchEnd, match.start),
          style: DefaultTextStyle.of(context).style,
        ));
      }

      spans.add(TextSpan(
        text: content.substring(match.start, match.end),
        style: DefaultTextStyle.of(context).style.copyWith(color: Colors.blue),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            debugPrint(
                'Tapped on hashtag: ${content.substring(match.start, match.end)}');
          },
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

class PostActions extends ConsumerStatefulWidget {
  final Post post;
  final Function(bool) onVote;
  final Function onComment;
  final Function onShare;
  const PostActions({
    super.key,
    required this.post,
    required this.onVote,
    required this.onComment,
    required this.onShare,
  });
  @override
  ConsumerState<PostActions> createState() => _PostActionsState();
}

class _PostActionsState extends ConsumerState<PostActions> {
  Map<String, dynamic>? previousData;
  @override
  Widget build(BuildContext context) {
    final asyncValue =
        ref.watch(getPostVoteCountAndStatusProvider(widget.post));
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
            PostStaticButton(
              icon: Mdi.commentOutline,
              label: 'Comments',
              onTap: widget.onComment,
            ),
            PostStaticButton(
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
              PostStaticButton(
                icon: Mdi.commentOutline,
                label: 'Comments',
                onTap: widget.onComment,
              ),
              PostStaticButton(
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
}

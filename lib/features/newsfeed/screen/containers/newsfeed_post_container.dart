import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';
import 'package:hash_balance/core/widgets/post_images_grid.dart';
import 'package:hash_balance/core/widgets/post_static_button.dart';
import 'package:hash_balance/core/widgets/video_player_widget.dart';
import 'package:hash_balance/core/widgets/vote_button.dart';
import 'package:hash_balance/features/community/controller/community_controller.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/newsfeed/controller/newsfeed_controller.dart';
import 'package:hash_balance/features/post/screen/edit_post_screen.dart';
import 'package:hash_balance/features/post/screen/hashtag_posts_screen.dart';
import 'package:hash_balance/features/post_share/screen/post_share_screen.dart';
import 'package:hash_balance/features/report/controller/report_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/vote_post/controller/vote_post_controller.dart';
import 'package:mdi/mdi.dart';
import 'package:flutter/foundation.dart';

import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/screen/comment_screen.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

class NewsfeedPostContainer extends ConsumerStatefulWidget {
  final UserModel author;
  final Post post;
  final Community community;

  const NewsfeedPostContainer({
    super.key,
    required this.author,
    required this.post,
    required this.community,
  });

  @override
  ConsumerState<NewsfeedPostContainer> createState() =>
      _NewsfeedPostContainerState();
}

class _NewsfeedPostContainerState extends ConsumerState<NewsfeedPostContainer> {
  TextEditingController commentTextController = TextEditingController();
  TextEditingController shareTextController = TextEditingController();
  bool? isLoading;
  UserModel? currentUser;

  void _navigateToHashtagPostsScreen(String hashtag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HashtagPostsScreen(filter: hashtag),
      ),
    );
  }

  void _navigateToOtherProfileScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OtherUserProfileScreen(targetUid: widget.author.uid),
      ),
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

  void _handleDeletePost(Post post) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this post?'),
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
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
            ),
          ],
        );
      },
    );
    if (result == true) {
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
  }

  void _handleReportPost() {
    TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
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
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.greenAccent,
                ),
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                'Submit',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
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
            color: ref.watch(preferredThemeProvider).first,
            child: Wrap(
              children: [
                if (currentUid != widget.post.uid)
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text('View $postUsername\'s Profile'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _navigateToOtherProfileScreen();
                    },
                  ),
                if (currentUid == widget.post.uid)
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit this post'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _handleEditPost();
                    },
                  ),
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
                  leading: const Icon(Icons.report),
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
  void didChangeDependencies() {
    currentUser = ref.read(userProvider);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(5),
      color: ref.watch(preferredThemeProvider).second,
      width: kIsWeb ? 600 : double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPostHeader(),
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

  Widget _buildPostHeader() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  _navigateToCommunityScreen(
                      widget.community, currentUser!.uid);
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
            _showPostOptionsMenu(currentUser!.uid, widget.author.name);
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
              content.substring(match.start, match.end)),
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
  final Post _post;
  final Function _onVote;
  final Function _onComment;
  final Function _onShare;

  const PostActions({
    super.key,
    required Post post,
    required Function(bool) onVote,
    required Function onComment,
    required Function onShare,
  })  : _post = post,
        _onVote = onVote,
        _onComment = onComment,
        _onShare = onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: ref
          .read(postControllerProvider.notifier)
          .getPostVoteCountAndStatus(_post),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final data = snapshot.data!;
          final upvotes = data['upvotes'] ?? 0;
          final downvotes = data['downvotes'] ?? 0;
          final status = data['userVoteStatus'];

          return LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: VoteButton(
                      icon: Icons.arrow_upward_rounded,
                      count: upvotes,
                      color: status == 'upvoted' ? Colors.orange : Colors.grey[600],
                      onTap: (isUpvote) => _onVote(isUpvote),
                      isUpvote: true,
                    ),
                  ),
                  Flexible(
                    child: VoteButton(
                      icon: Mdi.arrowDown,
                      count: downvotes,
                      color: status == 'downvoted' ? Colors.blue : Colors.grey[600],
                      onTap: (isUpvote) => _onVote(isUpvote),
                      isUpvote: false,
                    ),
                  ),
                  Flexible(
                    child: PostStaticButton(
                      icon: Mdi.commentOutline,
                      onTap: _onComment,
                    ),
                  ),
                  Flexible(
                    child: PostStaticButton(
                      icon: Mdi.shareOutline,
                      onTap: _onShare,
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

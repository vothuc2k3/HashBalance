import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/post_share/post_share_controller/post_share_controller.dart';
import 'package:mdi/mdi.dart';
import 'package:video_player/video_player.dart';

import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/screen/comment_screen.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PostContainer extends ConsumerStatefulWidget {
  final UserModel author;
  final Post post;
  final Community community;

  const PostContainer({
    super.key,
    required this.author,
    required this.post,
    required this.community,
  });

  @override
  ConsumerState<PostContainer> createState() => _PostContainerState();
}

class _PostContainerState extends ConsumerState<PostContainer> {
  TextEditingController commentTextController = TextEditingController();
  TextEditingController shareTextController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  String? _videoDuration;
  String? _currentPosition;
  bool? isLoading;
  UserModel? currentUser;

  void _togglePlayPause() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _isPlaying = _videoController!.value.isPlaying;
    });
  }

  void _votePost(bool userVote) async {
    final result = await ref
        .read(postControllerProvider.notifier)
        .votePost(widget.post, userVote);
    result.fold(
      (l) {
        showToast(false, l.toString());
      },
      (_) {},
    );
  }

  void _sharePost(String? content) async {
    final result = await ref
        .watch(postShareControllerProvider.notifier)
        .sharePost(postId: widget.post.id, content: content);
    result.fold((l) => showToast(false, l.message), (r) {
      showToast(true, 'Share successfully...');
    });
  }

  void _handleBlock() {}

  void _handleDeletePost(Post post) async {
    final result =
        await ref.watch(postControllerProvider.notifier).deletePost(post);
    result.fold(
      (l) {
        showToast(false, l.message);
      },
      (r) {
        showToast(true, 'Delete successfully...');
        setState(() {});
      },
    );
  }

  void _handleUnfollow() {}

  void _handleUnfriend() {}

  void _showPostOptionsMenu(String currentUid, String postUsername) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.person_remove),
                title: Text('Unfollow $postUsername'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleUnfollow();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_off),
                title: Text('Unfriend $postUsername'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleUnfriend();
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text('Block $postUsername'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleBlock();
                },
              ),
              if (currentUid == widget.post.uid)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleDeletePost(widget.post);
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
    String? membershipStatus;
    Post? pinnedPost;
    final result = await ref
        .watch(moderationControllerProvider.notifier)
        .fetchMembershipStatus(getMembershipId(uid, community.id));
    if (community.pinPostId != null) {
      final pinnedPostResult = await ref
          .watch(postControllerProvider.notifier)
          .fetchPostByPostId(community.pinPostId!);
      pinnedPostResult.fold((_) {}, (r) => pinnedPost = r);
    }

    result.fold(
      (l) {
        showToast(false, 'Unexpected error happened...');
      },
      (r) async {
        membershipStatus = r;
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityScreen(
              memberStatus: membershipStatus!,
              pinnedPost: pinnedPost,
              community: community,
            ),
          ),
        );
      },
    );
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

  @override
  void initState() {
    super.initState();
    if (widget.post.video != '') {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.post.video != null && widget.post.video != '') {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.post.video!),
      )..initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoDuration =
                  _formatDuration(_videoController!.value.duration);
            });
          }
        });

      _videoController!.addListener(_videoListener);

      if (mounted) {
        setState(() {});
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  void _videoListener() {
    if (_videoController!.value.position == _videoController!.value.duration) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _currentPosition = _formatDuration(_videoController!.value.position);
        });
      }
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
          _buildPostHeader(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.post.content),
                widget.post.image != '' && widget.post.video == ''
                    ? const SizedBox(height: 6)
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          if (widget.post.image != null || widget.post.image != '')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Image.network(
                widget.post.image!,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  } else {
                    return const Loading();
                  }
                },
              ),
            ),
          if (widget.post.video != '')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _videoController != null &&
                      _videoController!.value.isInitialized
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final videoAspectRatio =
                            _videoController!.value.aspectRatio;
                        final screenWidth = constraints.maxWidth;
                        final videoHeight = screenWidth / videoAspectRatio;
                        final maxHeight =
                            MediaQuery.of(context).size.height * 0.6;
                        final finalHeight =
                            videoHeight > maxHeight ? maxHeight : videoHeight;

                        return Center(
                          child: AspectRatio(
                            aspectRatio: videoAspectRatio,
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxHeight: finalHeight),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  VideoPlayer(_videoController!),
                                  if (!_isPlaying)
                                    Center(
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.play_arrow,
                                          color: Colors.white,
                                          size: 64.0,
                                        ),
                                        onPressed: _togglePlayPause,
                                      ),
                                    ),
                                  VideoProgressIndicator(
                                    _videoController!,
                                    allowScrubbing: true,
                                    colors: const VideoProgressColors(
                                      playedColor: Colors.red,
                                      backgroundColor: Colors.black54,
                                      bufferedColor: Colors.grey,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Text(
                                      _currentPosition ?? '0:00',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Text(
                                      _videoDuration ?? '0:00',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : const Loading(),
            ),
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
                  backgroundImage: NetworkImage(
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
                    '#${widget.community.name}',
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
            ref.watch(getPostCommentCountProvider(widget.post.id)).whenOrNull(
                  data: (count) {
                    return InkWell(
                      onTap: () => _navigateToCommentScreen(),
                      child: Text(
                        '$count Comments',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ) ??
                const Text(''),
            const SizedBox(width: 8),
            ref.watch(getPostShareCountProvider(widget.post.id)).whenOrNull(
                    data: (count) {
                  return Text(
                    '$count Shares',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  );
                }) ??
                const Text(''),
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

class PostActions extends ConsumerWidget {
  final Post _post;
  final Function _onVote;
  final Function _onComment;
  final Function _onShare;

  const PostActions({
    super.key,
    required Post post,
    required Function onVote,
    required Function onComment,
    required Function onShare,
  })  : _post = post,
        _onVote = onVote,
        _onComment = onComment,
        _onShare = onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildVoteButton(
          icon: Icons.arrow_upward_rounded,
          count: ref.watch(getPostVoteCountProvider(_post)).whenOrNull(
              data: (count) {
            return count['upvotes'];
          }),
          color: ref.watch(getPostVoteStatusProvider(_post)).whenOrNull(
              data: (status) {
            switch (status) {
              case true:
                return Colors.orange;
              case false:
                return Colors.grey[600];
              case null:
                return Colors.grey[600];
            }
          }),
          onTap: _onVote,
          isUpvote: true,
        ),
        _buildVoteButton(
          icon: Mdi.arrowDown,
          count: ref.watch(getPostVoteCountProvider(_post)).whenOrNull(
              data: (count) {
            return count['downvotes'];
          }),
          color: ref.watch(getPostVoteStatusProvider(_post)).whenOrNull(
              data: (status) {
            switch (status) {
              case true:
                return Colors.grey[600];
              case false:
                return Colors.blue;
              case null:
                return Colors.grey[600];
            }
          }),
          onTap: _onVote,
          isUpvote: false,
        ),
        _buildActionButton(
          icon: Mdi.commentOutline,
          label: 'Comments',
          onTap: _onComment,
        ),
        _buildActionButton(
          icon: Mdi.shareOutline,
          label: 'Share',
          onTap: _onShare,
        ),
      ],
    );
  }

  Widget _buildVoteButton({
    required IconData icon,
    required int? count,
    required Color? color,
    required Function onTap,
    required bool isUpvote,
  }) {
    return InkWell(
      onTap: () => onTap(isUpvote),
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

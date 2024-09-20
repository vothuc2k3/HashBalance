import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/post_share/post_share_controller/post_share_controller.dart';
import 'package:hash_balance/features/report/controller/report_controller.dart';
import 'package:hash_balance/features/theme/controller/theme_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/features/vote_post/controller/vote_post_controller.dart';
import 'package:video_player/video_player.dart';

import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/comment/screen/comment_screen.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PostContainer extends ConsumerStatefulWidget {
  final bool isMod;
  final UserModel author;
  final Post post;
  final Community community;
  final bool isPinnedPost;
  final Function(Post)? onPinPost;
  final Function(Post)? onUnPinPost;

  const PostContainer({
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
  ConsumerState<PostContainer> createState() => _PostContainerState();
}

class _PostContainerState extends ConsumerState<PostContainer> {
  late Stream<Map<String, dynamic>> _postVoteCountAndStatus;
  TextEditingController commentTextController = TextEditingController();
  TextEditingController shareTextController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  String? _videoDuration;
  String? _currentPosition;

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
    switch (userVote) {
      case true:
        final result = await ref
            .read(upvotePostControllerProvider.notifier)
            .votePost(widget.post);
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
        final result = await ref
            .read(downvotePostControllerProvider.notifier)
            .votePost(widget.post);
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
                Navigator.of(context).pop(); // Close the dialog
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
          child: Wrap(
            children: [
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
  void initState() {
    super.initState();
    if (widget.post.video != '') {
      _initializeVideo();
    }
    _postVoteCountAndStatus = ref
        .read(postControllerProvider.notifier)
        .getPostVoteCountAndStatus(widget.post);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: widget.isPinnedPost
            ? const Color(0xFF181C30)
            : ref.watch(preferredThemeProvider),
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
                Text(widget.post.content),
                widget.post.image != ''
                    ? const SizedBox.shrink()
                    : const SizedBox(height: 6),
              ],
            ),
          ),
          widget.post.image != null && widget.post.image != ''
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: CachedNetworkImage(
                    imageUrl: widget.post.image!,
                    progressIndicatorBuilder: (context, url, downloadProgress) {
                      return const Loading();
                    },
                  ),
                )
              : const SizedBox.shrink(),
          widget.post.video != null && widget.post.video != ''
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _videoController != null &&
                          _videoController!.value.isInitialized
                      ? Column(
                          children: [
                            AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: GestureDetector(
                                onTap: _togglePlayPause,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    VideoPlayer(
                                      _videoController!,
                                    ),
                                    if (!_isPlaying)
                                      const Center(
                                        child: Icon(
                                          Icons.play_arrow,
                                          color: Colors.white,
                                          size: 100.0,
                                        ),
                                      ),
                                    VideoProgressIndicator(
                                      _videoController!,
                                      allowScrubbing: true,
                                      colors: const VideoProgressColors(
                                        playedColor: Colors.red,
                                        backgroundColor: Colors.black,
                                        bufferedColor: Colors.grey,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      left: 8,
                                      child: Text(
                                        _currentPosition ?? '0:00',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Text(
                                        _videoDuration ?? '0:00',
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Loading(),
                )
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
          onShare: _showShareDialog,
          postVoteCountAndStatus: _postVoteCountAndStatus,
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
              _buildActionButton(
                icon: Icons.comment_rounded,
                label: 'Comments',
                onTap: _onComment,
              ),
              _buildActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
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

class VoteButton extends StatefulWidget {
  final IconData icon;
  final int? count;
  final Color? color;
  final Function onTap;
  final bool isUpvote;

  const VoteButton({
    super.key,
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
    required this.isUpvote,
  });

  @override
  VoteButtonState createState() => VoteButtonState();
}

class VoteButtonState extends State<VoteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(_controller);
  }

  void _handleTap() {
    if (mounted) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
    }
    widget.onTap(widget.isUpvote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: InkWell(
        onTap: _handleTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              Icon(widget.icon, color: widget.color, size: 20),
              const SizedBox(width: 4),
              Text(
                widget.count == null ? '0' : widget.count.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

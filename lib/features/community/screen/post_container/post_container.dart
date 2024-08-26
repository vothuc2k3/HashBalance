import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/post_share/post_share_controller/post_share_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:mdi/mdi.dart';
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

  const PostContainer({
    super.key,
    required this.isMod,
    required this.author,
    required this.post,
    required this.community,
    required this.isPinnedPost,
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
    result.fold((l) {
      showToast(false, l.toString());
    }, (_) {});
  }

  void _sharePost(String? content) async {
    final result = await ref
        .watch(postShareControllerProvider.notifier)
        .sharePost(postId: widget.post.id, content: content);
    result.fold((l) => showToast(false, l.message), (r) {
      showToast(true, 'Share successfully...');
    });
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

  void _handlePinPost() async {
    final result =
        await ref.read(moderationControllerProvider.notifier).pinPost(
              community: widget.community,
              post: widget.post,
            );
    result.fold((l) => showToast(false, l.message), (r) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _handleBlock() {}

  void _handleDelete() {}

  void _handleUnfollow() {}

  void _handleUnfriend() {}

  void _showBottomSheet(String currentUid, String postUsername) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (widget.isMod)
                ListTile(
                  leading: const Icon(Icons.person_remove),
                  title: const Text('Pin this post'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handlePinPost();
                  },
                ),
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
                    _handleDelete();
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.post.video!),
    )..initialize().then((_) {
        if (mounted) {
          setState(() {
            _videoDuration = _formatDuration(_videoController!.value.duration);
          });
        }
      });

    _videoController!.addListener(_videoListener);

    if (mounted) {
      setState(() {});
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
        color: widget.isPinnedPost ? Colors.blueGrey[900] : Colors.black,
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
          widget.post.image != ''
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
          widget.post.video != ''
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
          onTap: () => _navigateToOtherUserScreen(author.uid),
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
        IconButton(
          onPressed: () {
            _showBottomSheet(currentUser.uid, widget.author.name);
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
    return FutureBuilder<Map<String, dynamic>>(
      future: ref
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

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildVoteButton(
                icon: Icons.arrow_upward_rounded,
                count: upvotes,
                color: status == 'upvoted' ? Colors.orange : Colors.grey[600],
                onTap: (isUpvote) => _onVote(isUpvote),
                isUpvote: true,
              ),
              _buildVoteButton(
                icon: Mdi.arrowDown,
                count: downvotes,
                color: status == 'downvoted' ? Colors.blue : Colors.grey[600],
                onTap: (isUpvote) => _onVote(isUpvote),
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
        } else {
          return const Text('No data available');
        }
      },
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

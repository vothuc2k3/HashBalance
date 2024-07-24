import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mdi/mdi.dart';
import 'package:video_player/video_player.dart';

import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/comment/screen/comment_screen.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PostContainer extends ConsumerStatefulWidget {
  final UserModel user;
  final Post post;
  final Community community;

  const PostContainer({
    super.key,
    required this.user,
    required this.post,
    required this.community,
  });

  @override
  ConsumerState<PostContainer> createState() => _PostContainerState();
}

class _PostContainerState extends ConsumerState<PostContainer> {
  TextEditingController commentTextController = TextEditingController();
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

  void votePost(bool userVote) async {
    final result = await ref
        .read(postControllerProvider.notifier)
        .votePost(widget.post, userVote);
    result.fold((l) {
      showSnackBar(context, l.toString());
    }, (_) {});
  }

  void upvoteComment(String commentId, String authorUid) async {
    final result = await ref
        .read(commentControllerProvider.notifier)
        .upvote(commentId, authorUid);
    result.fold((l) {
      showSnackBar(context, l.toString());
    }, (_) {});
  }

  void downvoteComment(String commentId, String authorUid) async {
    final result = await ref
        .read(commentControllerProvider.notifier)
        .downvote(commentId, authorUid);
    result.fold((l) {
      showSnackBar(context, l.toString());
    }, (_) {});
  }

  void navigateToCommentScreen(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(
          postId: postId,
        ),
      ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPostHeader(widget.post, widget.user),
                const SizedBox(height: 4),
                Text(widget.post.content ?? ''),
                widget.post.image != ''
                    ? const SizedBox.shrink()
                    : const SizedBox(height: 6),
              ],
            ),
          ),
          widget.post.image != ''
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Image.network(
                    widget.post.image!,
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
                      : const CircularProgressIndicator(),
                )
              : const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildPostStat(user: widget.user),
          ),
        ],
      ),
    );
  }

  Widget _buildPostHeader(
    Post post,
    UserModel user,
  ) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(
            user.profileImage,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${user.name}',
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
            ref.watch(commentCountProvider(widget.post.id)).whenOrNull(
                  data: (count) {
                    return Text(
                      '$count Comments',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    );
                  },
                ) ??
                const Text(''),
            const SizedBox(width: 8),
            Text(
              '69 Shares',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
        const Divider(
          thickness: 0.5,
          indent: 5,
        ),
        PostActions(
          post: widget.post,
          onVote: votePost,
          onComment: () {
            navigateToCommentScreen(widget.post.id);
          },
          onShare: () {},
        ),
        const Divider(
          thickness: 0.5,
          indent: 5,
        ),

        //GET TOP COMMENT PROVIDER
        ref.watch(getTopCommentProvider(widget.post.id)).whenOrNull(
              data: (comment) {
                if (comment.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            child: ref
                                .watch(getUserByUidProvider(comment.first.uid))
                                .when(
                                  data: (user) {
                                    return CircleAvatar(
                                      backgroundImage:
                                          CachedNetworkImageProvider(
                                              user.profileImage),
                                      radius: 20,
                                    );
                                  },
                                  loading: () =>
                                      const CircularProgressIndicator(),
                                  error: (_, __) => const Icon(Icons.error),
                                ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: ref
                                  .watch(
                                      getUserByUidProvider(comment.first.uid))
                                  .whenOrNull(
                                data: (user) {
                                  return [
                                    Text('#${user.name}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall),
                                    const SizedBox(height: 4),
                                    Text(comment.first.content == null
                                        ? ''
                                        : comment.first.content!),
                                  ];
                                },
                              )!,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Row(
                        children: [
                          Text(
                            formatTime(comment.first.createdAt),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 3),
                          _buildVoteButton(
                            icon: Icons.arrow_upward_outlined,
                            count: ref
                                .watch(getCommentUpvoteCountProvider(
                                    comment.first.id))
                                .whenOrNull(data: (count) {
                              return count;
                            }),
                            color: ref
                                .watch(getCommentUpvoteStatusProvider(
                                    comment.first.id))
                                .whenOrNull(
                              data: (status) {
                                return status
                                    ? Colors.orange
                                    : Colors.grey[600];
                              },
                            ),
                            onTap: () {
                              upvoteComment(
                                  comment.first.id, comment.first.uid);
                            },
                          ),
                          _buildVoteButton(
                            icon: Icons.arrow_downward_outlined,
                            count: ref
                                .watch(getCommentDownvoteCountProvider(
                                    comment.first.id))
                                .whenOrNull(data: (count) {
                              return count;
                            }),
                            color: ref
                                .watch(getCommentDownvoteStatusProvider(
                                    comment.first.id))
                                .whenOrNull(
                              data: (status) {
                                return status ? Colors.blue : Colors.grey[600];
                              },
                            ),
                            onTap: () {
                              downvoteComment(
                                  comment.first.id, comment.first.uid);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ) ??
            const Text('Loading....'),
      ],
    );
  }

  Widget _buildVoteButton({
    required IconData icon,
    required int? count,
    required Color? color,
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
          color: ref.watch(getVoteStatusProvider(_post)).whenOrNull(
              data: (status) {
            if (status != null) {
              return status ? Colors.orange : Colors.grey[600];
            } else {
              return Colors.grey[600];
            }
          }),
          onTap: _onVote,
        ),
        _buildVoteButton(
          icon: Mdi.arrowDown,
          count: ref.watch(getPostVoteCountProvider(_post)).whenOrNull(
              data: (count) {
            return count['downvotes'];
          }),
          color: ref.watch(getVoteStatusProvider(_post)).whenOrNull(
              data: (status) {
            if (status != null) {
              return status ? Colors.blue : Colors.grey[600];
            } else {
              return Colors.grey[600];
            }
          }),
          onTap: _onVote,
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

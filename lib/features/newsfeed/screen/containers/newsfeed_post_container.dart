import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';
import 'package:hash_balance/core/widgets/post_actions.dart';
import 'package:hash_balance/core/widgets/post_header_widget.dart';
import 'package:hash_balance/core/widgets/post_images_grid.dart';
import 'package:hash_balance/core/widgets/video_player_widget.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/newsfeed/controller/newsfeed_controller.dart';
import 'package:hash_balance/features/post/screen/post_detail_screen.dart';
import 'package:hash_balance/features/post_share/screen/post_share_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/vote_post/controller/vote_post_controller.dart';

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
        }, (_) {});
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
        }, (_) {});
        break;
    }
  }

  void _sharePost() async {
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
        .watch(moderationControllerProvider.notifier)
        .fetchMembershipStatus(
          getMembershipId(uid: uid, communityId: community.id),
        );

    result.fold(
      (l) {
        showToast(false, 'Unexpected error happened...');
      },
      (r) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityScreen(
              communityId: community.id,
            ),
          ),
        );
      },
    );
  }

  void _navigateToPostDetailScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          post: widget.post,
          author: widget.author,
          community: widget.community,
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    currentUser = ref.read(userProvider);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToPostDetailScreen(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(5),
        color: ref.watch(preferredThemeProvider).second,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PostHeaderWidget.community(
              community: widget.community,
              createdAt: widget.post.createdAt,
              onCommunityTap: () => _navigateToCommunityScreen(
                widget.community,
                widget.author.uid,
              ),
              onOptionsTap: () => _showPostOptionsMenu(
                widget.author.uid,
                widget.author.name,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.post.content),
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
      ),
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
          onComment: () => _navigateToCommentScreen(),
          onShare: _sharePost,
        ),
        const Divider(
          thickness: 0.5,
          indent: 5,
        ),
      ],
    );
  }
}

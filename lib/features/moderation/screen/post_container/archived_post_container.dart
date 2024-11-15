import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/post_header_widget.dart';
import 'package:hash_balance/core/widgets/post_images_grid.dart';
import 'package:hash_balance/core/widgets/video_player_widget.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';

import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';


class ArchivedPostContainer extends ConsumerStatefulWidget {
  final UserModel author;
  final Post post;
  final String communityId;
  final Function(Post) unarchivePost;

  const ArchivedPostContainer({
    super.key,
    required this.author,
    required this.post,
    required this.communityId,
    required this.unarchivePost,
  });

  @override
  ConsumerState<ArchivedPostContainer> createState() =>
      _ArchivedPostContainerState();
}

class _ArchivedPostContainerState extends ConsumerState<ArchivedPostContainer> {
  TextEditingController commentTextController = TextEditingController();
  TextEditingController shareTextController = TextEditingController();

  void _handleUnarchivePost(String postId) async {
    showCustomAlertDialog(
      context: context,
      title: 'Unarchive Post',
      content: 'Unarchiving will show this post in newsfeed, are you sure?',
      backgroundColor: ref.watch(preferredThemeProvider).second,
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
            widget.unarchivePost(widget.post);
            Navigator.of(context).pop();
          },
          child: const Text('Unarchive'),
        ),
      ],
    );
  }

  void _handleDeletePost(Post post) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).second,
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.greenAccent,
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
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

  void _showPostOptionsMenu(String currentUid, String postUsername) {
    showModalBottomSheet(
      backgroundColor: ref.watch(preferredThemeProvider).second,
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleDeletePost(widget.post);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive),
                title: const Text('Unarchive'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleUnarchivePost(widget.post.id);
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: ref.watch(preferredThemeProvider).second,
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
                PostHeaderWidget.author(
                  author: widget.author,
                  createdAt: widget.post.createdAt,
                  onAuthorTap: () =>
                      _navigateToOtherUserScreen(widget.author.uid),
                  onOptionsTap: () =>
                      _showPostOptionsMenu(widget.author.uid, widget.author.name),
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
                  onTap: () {},
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
                  onTap: () {},
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
        ElevatedButton(
          onPressed: () => _handleUnarchivePost(widget.post.id),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
          ),
          child: const Text('Unarchive'),
        ),
        const Divider(
          thickness: 0.5,
          indent: 5,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/post_header_widget.dart';
import 'package:hash_balance/core/widgets/post_images_grid.dart';
import 'package:hash_balance/core/widgets/video_player_widget.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

class RejectedPostContainer extends ConsumerWidget {
  const RejectedPostContainer({
    super.key,
    required this.post,
    required this.author,
    required this.community,
  });

  final Post post;
  final UserModel author;
  final Community community;

  void _navigateToOtherUserScreen(
      String currentUserUid, String uid, BuildContext context) {
    if (currentUserUid != uid) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherUserProfileScreen(targetUid: uid),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UserProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(userProvider);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(5),
      color: ref.watch(preferredThemeProvider).second,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PostHeaderWidget.author(
            author: author,
            createdAt: post.createdAt,
            onAuthorTap: () => _navigateToOtherUserScreen(
              currentUser!.uid,
              author.uid,
              context,
            ),
            onOptionsTap: () {},
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(post.content),
                post.images != null && post.video == ''
                    ? const SizedBox(height: 6)
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          if (post.images != null && post.images!.isNotEmpty)
            PostImagesGrid(images: post.images!),
          if (post.video != null && post.video!.isNotEmpty)
            VideoPlayerWidget(videoUrl: post.video!),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "This post has been rejected by the moderator.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      ref.watch(preferredThemeProvider).approveButtonColor,
                ),
                child: const Text(
                  'Approve Post',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _handleDeletePost(post, context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      ref.watch(preferredThemeProvider).declineButtonColor,
                ),
                child: const Text(
                  'Delete Post',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleDeletePost(
    Post post,
    BuildContext context,
    WidgetRef ref,
  ) async {
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/post_header_widget.dart';
import 'package:hash_balance/core/widgets/post_images_grid.dart';
import 'package:hash_balance/core/widgets/video_player_widget.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PlainPostContainer extends ConsumerWidget {
  const PlainPostContainer({
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
        ],
      ),
    );
  }
}

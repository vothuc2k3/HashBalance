import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/post_share/controller/post_share_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/widget/timeline_post_container.dart';
import 'package:hash_balance/models/conbined_models/post_share_data_model.dart';
import 'package:hash_balance/core/utils.dart';

class PostShareContainer extends ConsumerWidget {
  final PostShareDataModel postShareData;

  const PostShareContainer({
    required this.postShareData,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProvider)!;
    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                  postShareData.author.profileImage,
                ),
                radius: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${postShareData.author.name} has shared a post',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      formatTime(postShareData.postShare.createdAt),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (postShareData.postShare.uid == currentUser.uid)
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onPressed: () => _showPostShareOptions(context, ref),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (postShareData.postShare.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                postShareData.postShare.content,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          const Divider(color: Colors.grey),
          TimelinePostContainer(
            post: postShareData.post,
            author: postShareData.author,
            community: postShareData.community,
          ),
        ],
      ),
    );
  }

  void _showPostShareOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: ref.watch(preferredThemeProvider).first,
          child: SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Share Content'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Implement edit share content functionality here
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Delete this Share'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleDeleteShare(context, ref);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Close'),
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

  void _handleDeleteShare(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this share?'),
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
                Navigator.of(context).pop();
                final result = await ref
                    .read(postShareControllerProvider.notifier)
                    .deletePostShareById(postShareData.postShare.id);
                result.fold(
                  (l) => showToast(false, l.message),
                  (_) => showToast(true, 'Share deleted successfully'),
                );
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
  }
}

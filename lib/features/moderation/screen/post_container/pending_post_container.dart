import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/post_images_grid.dart';
import 'package:hash_balance/core/widgets/video_player_widget.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';

import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PendingPostContainer extends ConsumerStatefulWidget {
  final UserModel _author;
  final Post _post;
  final Function(Post, String) _handlePostApproval;

  const PendingPostContainer({
    super.key,
    required UserModel author,
    required Post post,
    required Function(Post, String) handlePostApproval,
  })  : _author = author,
        _post = post,
        _handlePostApproval = handlePostApproval;

  @override
  ConsumerState<PendingPostContainer> createState() =>
      _PendingPostContainerState();
}

class _PendingPostContainerState extends ConsumerState<PendingPostContainer> {
  TextEditingController commentTextController = TextEditingController();
  TextEditingController shareTextController = TextEditingController();

  void _navigateToOtherUserScreen(String currentUid) {
    switch (currentUid == widget._author.uid) {
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
                OtherUserProfileScreen(targetUid: widget._author.uid),
          ),
        );
        break;
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
                _buildPostHeader(widget._post, widget._author),
                const SizedBox(height: 4),
                Text(widget._post.content),
                widget._post.images != null && widget._post.images!.isNotEmpty
                    ? const SizedBox.shrink()
                    : const SizedBox(height: 6),
              ],
            ),
          ),
          widget._post.images != null && widget._post.images!.isNotEmpty
              ? PostImagesGrid(images: widget._post.images!)
              : const SizedBox.shrink(),
          widget._post.video != null && widget._post.video != ''
              ? VideoPlayerWidget(videoUrl: widget._post.video!)
              : const SizedBox.shrink(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green),
                onPressed: () {
                  widget._handlePostApproval(widget._post, 'Approved');
                },
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () {
                  widget._handlePostApproval(widget._post, 'Rejected');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostHeader(
    Post post,
    UserModel author,
  ) {
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
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/post_header_widget.dart';
import 'package:hash_balance/core/widgets/post_images_grid.dart';
import 'package:hash_balance/core/widgets/video_player_widget.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';

import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

class ReportPostContainer extends ConsumerStatefulWidget {
  final UserModel _author;
  final Post _post;

  const ReportPostContainer({
    super.key,
    required UserModel author,
    required Post post,
  })  : _author = author,
        _post = post;

  @override
  ConsumerState<ReportPostContainer> createState() =>
      _ReportPostContainerState();
}

class _ReportPostContainerState extends ConsumerState<ReportPostContainer> {
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
                PostHeaderWidget.author(
                  author: widget._author,
                  createdAt: widget._post.createdAt,
                  onAuthorTap: () =>
                      _navigateToOtherUserScreen(widget._author.uid),
                  onOptionsTap: () {},
                ),
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
        ],
      ),
    );
  }
}

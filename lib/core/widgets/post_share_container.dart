import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hash_balance/features/user_profile/screen/widget/timeline_post_container.dart';
import 'package:hash_balance/models/conbined_models/post_share_data_model.dart';
import 'package:hash_balance/core/utils.dart';

class PostShareContainer extends StatelessWidget {
  final PostShareDataModel postShareData;

  const PostShareContainer({
    required this.postShareData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Shared content message
          if (postShareData.postShare.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                postShareData.postShare.content,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          const Divider(color: Colors.grey),
          // Shared Post Container
          TimelinePostContainer(
            post: postShareData.post,
            author: postShareData.author,
            community: postShareData.community,
          ),
        ],
      ),
    );
  }
}

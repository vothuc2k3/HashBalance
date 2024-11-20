import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PostHeaderWidget extends StatelessWidget {
  final String displayName;
  final String profileImageUrl;
  final Timestamp createdAt;
  final VoidCallback onTap;
  final VoidCallback onOptionsTap;

  const PostHeaderWidget._({
    required this.displayName,
    required this.profileImageUrl,
    required this.createdAt,
    required this.onTap,
    required this.onOptionsTap,
  });

  factory PostHeaderWidget.author({
    required UserModel author,
    required Timestamp createdAt,
    required VoidCallback onAuthorTap,
    required VoidCallback onOptionsTap,
  }) {
    return PostHeaderWidget._(
      displayName: author.name,
      profileImageUrl: author.profileImage,
      createdAt: createdAt,
      onTap: onAuthorTap,
      onOptionsTap: onOptionsTap,
    );
  }

  factory PostHeaderWidget.community({
    required Community community,
    required Timestamp createdAt,
    required VoidCallback onCommunityTap,
    required VoidCallback onOptionsTap,
  }) {
    return PostHeaderWidget._(
      displayName: community.name,
      profileImageUrl: community.profileImage,
      createdAt: createdAt,
      onTap: onCommunityTap,
      onOptionsTap: onOptionsTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              InkWell(
                onTap: onTap,
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(profileImageUrl),
                  radius: 20,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatTime(createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onOptionsTap,
          icon: const Icon(Icons.more_horiz),
        ),
      ],
    );
  }
}

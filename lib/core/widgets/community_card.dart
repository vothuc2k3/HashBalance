import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hash_balance/models/community_model.dart';

class CommunityCard extends StatelessWidget {
  final Community community;
  final int memberCount;
  final VoidCallback onTap;
  final Color themeProvider;

  const CommunityCard({
    super.key,
    required this.community,
    required this.memberCount,
    required this.onTap,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        tileColor: themeProvider,
        leading: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(
            community.profileImage,
          ),
          radius: 30,
        ),
        title: Text(
          community.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          community.description,
          style: const TextStyle(color: Colors.white70),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, color: Colors.white70),
            Text(
              memberCount.toString(),
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

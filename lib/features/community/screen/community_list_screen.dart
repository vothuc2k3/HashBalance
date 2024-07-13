import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/push_notification/controller/push_notification_controller.dart';
import 'package:hash_balance/models/community_model.dart';

class CommunityListScreen extends ConsumerStatefulWidget {
  const CommunityListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CommunityListScreenState();
}

class _CommunityListScreenState extends ConsumerState<CommunityListScreen> {
  _navigateToCommunityScreen(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityScreen(
          community: community,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communityList = ref.watch(getTopCommunityListProvider);
    return Scaffold(
      body: communityList.when(
        data: (communities) {
          if (communities == null || communities.isEmpty) {
            return Center(
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.abc),
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                return Card(
                  color: Colors.black,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
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
                    subtitle: const Text(
                      'THIS IS A COMMUNITY',
                      style: TextStyle(color: Colors.white70),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, color: Colors.white70),
                        SizedBox(height: 4),
                        Text(
                          // '${community.members.length} members',
                          '82964',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToCommunityScreen(community),
                  ),
                );
              },
            );
          }
        },
        error: (error, stackTrace) => ErrorText(error: error.toString()),
        loading: () => const Loading(),
      ),
    );
  }
}

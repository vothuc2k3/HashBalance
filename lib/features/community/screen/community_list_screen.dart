import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';

class CommunityListScreen extends ConsumerStatefulWidget {
  const CommunityListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CommunityListScreenState();
}

class _CommunityListScreenState extends ConsumerState<CommunityListScreen> {
  @override
  Widget build(BuildContext context) {
    final communityList = ref.watch(getTopCommunityListProvider);
    return Scaffold(
      body: communityList.when(
        data: (communities) {
          if (communities == null || communities.isEmpty) {
            return const Center(
              child: Text(
                'There are no communities in the entire system...',
                style: TextStyle(color: Colors.white),
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
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people, color: Colors.white70),
                        const SizedBox(height: 4),
                        Text(
                          '${community.members.length} members',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Navigate to community details or handle tap
                    },
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

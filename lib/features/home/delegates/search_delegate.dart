import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/screen/other_community_screen.dart';
import 'package:hash_balance/features/search/controller/search_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/models/user_model.dart';

class SearchCommunityDelegate extends SearchDelegate {
  final WidgetRef ref;
  SearchCommunityDelegate(this.ref);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return null;
  }

  @override
  Widget buildResults(BuildContext context) {
    return const SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suggestions:',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            InkWell(
              onTap: () {
                query = '#';
                showSuggestions(context);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.tag, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      '#',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () {
                query = '#=';
                showSuggestions(context);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.people, color: Colors.white),
                    SizedBox(width: 10),
                    Text('#=', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: () {
                query = '=';
                showSuggestions(context);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.article, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      '=',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ref.watch(searchProvider(query)).when(
          data: (data) {
            if (query.startsWith('#=')) {
              return ListView.separated(
                itemCount: data.length,
                itemBuilder: (BuildContext context, int index) {
                  final community = data[index];
                  return Card(
                    color: Colors.black87,
                    margin: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            CachedNetworkImageProvider(community.profileImage),
                      ),
                      title: Text(
                        '#=${community.name}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        navigateToCommunityScreen(context, community.name);
                      },
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider(color: Colors.grey);
                },
              );
            } else if (query.startsWith('#')) {
              final currentUser = ref.watch(userProvider);
              return ListView.separated(
                itemCount: data.length,
                itemBuilder: (BuildContext context, int index) {
                  UserModel user = data[index];
                  if (user.uid == currentUser!.uid) {
                    return const SizedBox.shrink();
                  }
                  return Card(
                    color: Colors.black87,
                    margin: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            CachedNetworkImageProvider(user.profileImage),
                      ),
                      title: Text(
                        '#${user.name}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        navigateToProfileScreen(context, user.uid);
                      },
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  final user = data[index];
                  if (user.uid == currentUser!.uid) {
                    return const SizedBox.shrink();
                  }
                  return const Divider(color: Colors.grey);
                },
              );
            } else {
              // TODO: if query.startsWith('='), return posts
              return const SizedBox();
            }
          },
          error: (error, stackTrace) => ErrorText(error: error.toString()),
          loading: () => const Loading(),
        );
  }

  void navigateToCommunityScreen(BuildContext context, String communityName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherCommunityScreen(
          name: communityName,
        ),
      ),
    );
  }

  void navigateToProfileScreen(BuildContext context, String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(
          uid: uid,
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/search/controller/search_controller.dart';
import 'package:routemaster/routemaster.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';

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
      return const SizedBox();
    }

    return ref.watch(searchProvider(query)).when(
          data: (data) {
            if (query.startsWith('#=')) {
              return ListView.separated(
                itemCount: data.length,
                itemBuilder: (BuildContext context, int index) {
                  final community = data[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(community.profileImage),
                    ),
                    title: Text('#=${community.name}'),
                    onTap: () {
                      navigateToCommunityScreen(context, community.name);
                    },
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider();
                },
              );
            } else if (query.startsWith('#')) {
              return ListView.separated(
                itemCount: data.length,
                itemBuilder: (BuildContext context, int index) {
                  final currentUser = ref.watch(userProvider);
                  final user = data[index];
                  if (user.uid == currentUser!.uid) {
                    return const SizedBox(height: 1);
                  }
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(user.profileImage),
                    ),
                    title: Text('#${user.name}'),
                    onTap: () {
                      navigateToProfileScreen(context, user.uid);
                    },
                  );
                },
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider();
                },
              );
            } else {
              // TODO: if query.startWith('='), returns posts
              return const SizedBox(height: 0);
            }
          },
          error: (error, stackTrace) => ErrorText(
            error: error.toString(),
          ),
          loading: () => const Loading(),
        );
  }

  void navigateToCommunityScreen(BuildContext context, String communityName) {
    Routemaster.of(context).push('/community/view/$communityName');
  }

  void navigateToProfileScreen(BuildContext context, String uid) {
    Routemaster.of(context).push('/user-profile/view/$uid');
  }
}

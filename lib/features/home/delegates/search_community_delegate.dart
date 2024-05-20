import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return ref.watch(searchProvider(query)).when(
          data: (communities) {
            return ListView.separated(
              itemCount: communities.length,
              itemBuilder: (BuildContext context, int index) {
                final community = communities[index];
                return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(community.profileImage),
                    ),
                    title: Text('#=${community.name}'),
                    onTap: () {
                      navigateToCommunityScreen(context, community.name);
                    });
              },
              separatorBuilder: (BuildContext context, int index) {
                return const Divider();
              },
            );
          },
          error: (error, stackTrace) => ErrorText(
            error: error.toString(),
          ),
          loading: () => const LoadingCircular(),
        );
  }

  void navigateToCommunityScreen(BuildContext context, String communityName) {
    Routemaster.of(context).push('/#=/$communityName');
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/models/community.dart';
import 'package:routemaster/routemaster.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/theme/pallette.dart';

class CommunityListDrawer extends ConsumerStatefulWidget {
  const CommunityListDrawer({super.key});

  @override
  CommunityListDrawerState createState() => CommunityListDrawerState();
}

class CommunityListDrawerState extends ConsumerState<CommunityListDrawer> {
  late Future<List<Community>> _futureCommunities;

  @override
  void initState() {
    super.initState();
    _futureCommunities = ref.read(userCommunitiesProvider.future);
  }

  Future<bool> checkIsMod(String communityName, WidgetRef ref) async {
    return await ref
        .read(communityControllerProvider.notifier)
        .isMod(communityName);
  }

  void navigateToCreateCommunityScreen(BuildContext context) {
    Routemaster.of(context).push('/community/create');
  }

  void navigateToOtherCommunityScreen(
    BuildContext context,
    String communityName,
  ) {
    Routemaster.of(context).push('/community/view/$communityName');
  }

  void navigateToMyCommunityScreen(
    BuildContext context,
    String communityName,
  ) {
    Routemaster.of(context).push('/community/my-community/$communityName');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<List<Community>>(
        future: _futureCommunities,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loading();
          }
          if (snapshot.hasError) {
            return ErrorText(error: snapshot.error.toString());
          }
          final communities = snapshot.data!;
          return SafeArea(
            child: Column(
              children: [
                ListTile(
                  title: const Text(
                    'Create your new Community',
                    style: TextStyle(
                      color: Pallete.whiteColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  leading: const Icon(
                    Icons.add,
                  ),
                  onTap: () {
                    navigateToCreateCommunityScreen(context);
                  },
                ),
                const Divider(
                  height: 0.1,
                  thickness: 2,
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: communities.length,
                    itemBuilder: (BuildContext context, int index) {
                      final community = communities[index];
                      return FutureBuilder<bool>(
                        future: checkIsMod(community.name, ref),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Loading();
                          }
                          if (snapshot.hasError) {
                            return ErrorText(error: snapshot.error.toString());
                          }
                          final isMod = snapshot.data!;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(community.profileImage),
                            ),
                            title: Text(
                              '#=${community.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () {
                              switch (isMod) {
                                case true:
                                  navigateToMyCommunityScreen(
                                      context, community.name);
                                  break;
                                case false:
                                  navigateToOtherCommunityScreen(
                                      context, community.name);
                                  break;
                              }
                            },
                          );
                        },
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const Divider();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

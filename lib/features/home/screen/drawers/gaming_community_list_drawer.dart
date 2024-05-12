import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/gaming_community/controller/gaming_comunity_controller.dart';
import 'package:hash_balance/models/gaming_community_model.dart';
import 'package:routemaster/routemaster.dart';

class GameCommunityListDrawer extends ConsumerWidget {
  const GameCommunityListDrawer({super.key});

  void navigateToCreateCommunityScreen(BuildContext context) {
    Routemaster.of(context).push('/create-community');
  }

  void navigateToCommunityScreen(
      BuildContext context, GamingCommunityModel community) {
    Routemaster.of(context).push('/#=/${community.name}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: const Text(
                'Create your new Community',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              leading: const Icon(
                Icons.add,
              ),
              onTap: () {
                navigateToCreateCommunityScreen(context);
              },
            ),
            ref.watch(userCommunitiesProvider).when(
                data: (communities) => Expanded(
                      child: ListView.builder(
                        itemCount: communities.length,
                        itemBuilder: (BuildContext context, int index) {
                          final community = communities[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(community.profileImage),
                            ),
                            title: Text('#=${community.name}'),
                            onTap: () {
                              navigateToCommunityScreen(context, community);
                            },
                          );
                        },
                      ),
                    ),
                error: ((error, stackTrace) {
                  return ErrorText(
                    error: error.toString(),
                  );
                }),
                loading: () {
                  return const LoadingCircular();
                }),
          ],
        ),
      ),
    );
  }
}

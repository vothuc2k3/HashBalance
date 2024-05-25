import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:routemaster/routemaster.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/theme/pallette.dart';

class CommunityListDrawer extends ConsumerWidget {
  const CommunityListDrawer({super.key});

  void navigateToCreateCommunityScreen(BuildContext context) {
    Routemaster.of(context).push('/create-community');
  }

  void navigateToCommunityScreen(BuildContext context, String communityName) {
    Routemaster.of(context).push('/#=/$communityName');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_result
    ref.refresh(userCommunitiesProvider);
    return Drawer(
      child: SafeArea(
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
            ref.watch(userCommunitiesProvider).when(
                  data: (communities) => Expanded(
                    child: ListView.separated(
                      itemCount: communities.length,
                      itemBuilder: (BuildContext context, int index) {
                        final community = communities[index];
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
                            navigateToCommunityScreen(
                              context,
                              community.name,
                            );
                          },
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const Divider();
                      },
                    ),
                  ),
                  error: ((error, stackTrace) {
                    return ErrorText(
                      error: error.toString(),
                    );
                  }),
                  loading: () {
                    return const Loading();
                  },
                ),
          ],
        ),
      ),
    );
  }
}

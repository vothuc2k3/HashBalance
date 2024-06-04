import 'package:animated_icon/animated_icon.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:routemaster/routemaster.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/theme/pallette.dart';

class CommunityListDrawer extends ConsumerWidget {
  const CommunityListDrawer({super.key});

  void navigateToCreateCommunityScreen(BuildContext context) {
    Routemaster.of(context).push('/community/create');
  }

  void navigateToViewCommunityScreen(
    BuildContext context,
    Community community,
  ) {
    Routemaster.of(context).push('/community/view/${community.name}');
  }

  void navigateToMyCommunityScreen(
    BuildContext context,
    Community community,
  ) {
    Routemaster.of(context).push('/community/my-community/${community.name}');
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
            const Divider(),
            const ListTile(
              title: Text(
                'Your Communities',
                style: TextStyle(
                  color: Pallete.whiteColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: Icon(
                Icons.admin_panel_settings,
              ),
            ),
            ref.watch(myCommunitiesProvider).when(
              data: (communities) {
                final hasCommunity = communities.isNotEmpty;
                return Expanded(
                  child: hasCommunity
                      ? ListView.separated(
                          itemCount: communities.length,
                          itemBuilder: (BuildContext context, int index) {
                            final community = communities[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(
                                    community.profileImage),
                              ),
                              title: Text(
                                '#=${community.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                navigateToMyCommunityScreen(
                                  context,
                                  community,
                                );
                              },
                            );
                          },
                          separatorBuilder: (context, index) {
                            return const Divider();
                          },
                        )
                      : Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('WOW! SUCH EMPTY...'),
                              AnimateIcon(
                                height: 30,
                                width: 30,
                                onTap: () {},
                                iconType: IconType.continueAnimation,
                                animateIcon: AnimateIcons.bell,
                                color: Pallete.whiteColor,
                              ),
                            ],
                          ),
                        ),
                );
              },
              error: (error, stackTrace) {
                return ErrorText(error: error.toString());
              },
              loading: () {
                return const Loading();
              },
            ),
            const Divider(),
            const ListTile(
              title: Text(
                'Joined Communities',
                style: TextStyle(
                  color: Pallete.whiteColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: Icon(
                Icons.people,
              ),
            ),
            ref.watch(userCommunitiesProvider).when(
              data: (communities) {
                final hasCommunity = communities.isNotEmpty;
                return Expanded(
                  child: hasCommunity
                      ? ListView.separated(
                          itemCount: communities.length,
                          itemBuilder: (BuildContext context, int index) {
                            final community = communities[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(
                                    community.profileImage),
                              ),
                              title: Text(
                                '#=${community.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                navigateToViewCommunityScreen(
                                  context,
                                  community,
                                );
                              },
                            );
                          },
                          separatorBuilder: (context, index) {
                            return const Divider();
                          },
                        )
                      : Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('WOW! SUCH EMPTY...'),
                              AnimateIcon(
                                height: 30,
                                width: 30,
                                onTap: () {},
                                iconType: IconType.continueAnimation,
                                animateIcon: AnimateIcons.bell,
                                color: Pallete.whiteColor,
                              ),
                            ],
                          ),
                        ),
                );
              },
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

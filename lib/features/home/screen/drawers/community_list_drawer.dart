import 'package:animated_icon/animated_icon.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/splash/splash_screen.dart';
import 'package:hash_balance/core/common/widgets/dashed_line_divider.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/screen/create_community_screen.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/models/community_model.dart';

import 'package:hash_balance/core/common/widgets/error_text.dart';
import 'package:hash_balance/core/common/widgets/loading.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/theme/pallette.dart';

class CommunityListDrawer extends ConsumerStatefulWidget {
  const CommunityListDrawer({super.key});

  @override
  ConsumerState<CommunityListDrawer> createState() =>
      _CommunityListDrawerState();
}

class _CommunityListDrawerState extends ConsumerState<CommunityListDrawer> {
  void navigateToCreateCommunityScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCommunityScreen(),
      ),
    );
  }

  void _navigateToCommunityScreen(Community community, String uid) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
    String? membershipStatus;
    final result = await ref
        .watch(moderationControllerProvider.notifier)
        .fetchMembershipStatus(getMembershipId(uid, community.id));

    result.fold(
      (l) {
        showToast(false, 'Unexpected error happened...');
      },
      (r) async {
        membershipStatus = r;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityScreen(
              memberStatus: membershipStatus!,
              community: community,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_result
    ref.refresh(userCommunitiesProvider);
    final currentUser = ref.watch(userProvider)!;

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
                                _navigateToCommunityScreen(
                                  community,
                                  currentUser.uid,
                                );
                              },
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const DashedLineDivider.horizontal(),
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
                                _navigateToCommunityScreen(
                                    community, currentUser.uid);
                              },
                            );
                          },
                          separatorBuilder: (context, index) {
                            return const DashedLineDivider.horizontal();
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

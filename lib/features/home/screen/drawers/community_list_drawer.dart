import 'package:animated_icon/animated_icon.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/screen/create_community_screen.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/theme/pallette.dart';

class CommunityListDrawer extends ConsumerWidget {
  const CommunityListDrawer({super.key});

  void navigateToCreateCommunityScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCommunityScreen(),
      ),
    );
  }

  void _navigateToCommunityScreen(
    BuildContext context,
    WidgetRef ref,
    Community community,
    String uid,
  ) async {
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
        await Navigator.pushReplacement(
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
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProvider)!;

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF001F3F),
              Color(0xFF0074D9),
            ],
          ),
        ),
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
              ).animate().fadeIn(duration: 800.ms),
              const Divider(),
              ref.watch(userCommunitiesProvider).when(
                    data: (communities) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownSearch<Community>(
                          items: communities,
                          itemAsString: (Community community) =>
                              "#${community.name}",
                          onChanged: (Community? selectedCommunity) {
                            if (selectedCommunity != null) {
                              _navigateToCommunityScreen(
                                context,
                                ref,
                                selectedCommunity,
                                currentUser.uid,
                              );
                            }
                          },
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: "Search Communities",
                              labelStyle: const TextStyle(color: Colors.white),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: Colors.white),
                              ),
                            ),
                          ),
                          dropdownButtonProps: const DropdownButtonProps(
                            icon: Icon(Icons.search, color: Colors.white),
                          ),
                          popupProps: PopupProps.menu(
                            showSearchBox: true,
                            searchFieldProps: const TextFieldProps(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.all(8),
                                hintText: "Type to search...",
                              ),
                            ),
                            itemBuilder: (context, item, isSelected) {
                              return ListTile(
                                title: Text("#${item.name}"),
                                leading: CircleAvatar(
                                  backgroundImage: CachedNetworkImageProvider(
                                    item.profileImage,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ).animate().fadeIn(duration: 800.ms);
                    },
                    error: (e, s) => ErrorText(
                      error: e.toString(),
                    ).animate().fadeIn(duration: 800.ms),
                    loading: () =>
                        const Loading().animate().fadeIn(duration: 800.ms),
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
              Expanded(
                child: ref.watch(myCommunitiesProvider).when(
                  data: (communities) {
                    return communities.isNotEmpty
                        ? ListView.separated(
                            itemCount: communities.length,
                            itemBuilder: (BuildContext context, int index) {
                              final community = communities[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: CachedNetworkImageProvider(
                                      community.profileImage),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      '#${community.name}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    community.type == 'Public'
                                        ? const Icon(Icons.public)
                                        : community.type == 'Private'
                                            ? const Icon(
                                                Icons.private_connectivity)
                                            : const Icon(
                                                (Icons.lock),
                                              )
                                  ],
                                ),
                                onTap: () {
                                  _navigateToCommunityScreen(
                                    context,
                                    ref,
                                    community,
                                    currentUser.uid,
                                  );
                                },
                              );
                            },
                            separatorBuilder: (context, index) {
                              return const SizedBox(height: 3);
                            },
                          ).animate().fadeIn(duration: 800.ms)
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
                          ).animate().fadeIn(duration: 800.ms);
                  },
                  error: (error, stackTrace) {
                    return ErrorText(
                      error: error.toString(),
                    ).animate().fadeIn(duration: 800.ms);
                  },
                  loading: () {
                    return const Loading().animate().fadeIn(duration: 800.ms);
                  },
                ),
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
              ).animate().fadeIn(duration: 800.ms),
              Expanded(
                child: ref.watch(userCommunitiesProvider).when(
                  data: (communities) {
                    return communities.isNotEmpty
                        ? ListView.separated(
                            itemCount: communities.length,
                            itemBuilder: (BuildContext context, int index) {
                              final community = communities[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: CachedNetworkImageProvider(
                                      community.profileImage),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      '#${community.name}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    community.type == 'Public'
                                        ? const Icon(Icons.public)
                                        : community.type == 'Private'
                                            ? const Icon(
                                                Icons.private_connectivity)
                                            : const Icon(
                                                (Icons.lock),
                                              )
                                  ],
                                ),
                                onTap: () {
                                  _navigateToCommunityScreen(
                                    context,
                                    ref,
                                    community,
                                    currentUser.uid,
                                  );
                                },
                              );
                            },
                            separatorBuilder: (context, index) {
                              return const SizedBox(height: 3);
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
              ).animate().fadeIn(duration: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}

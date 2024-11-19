import 'package:animated_icon/animated_icon.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/screen/create_community_screen.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/mod_tools_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/theme/pallette.dart';

class CommunityListDrawer extends ConsumerStatefulWidget {
  const CommunityListDrawer({super.key});

  @override
  CommunityListDrawerState createState() => CommunityListDrawerState();
}

class CommunityListDrawerState extends ConsumerState<CommunityListDrawer>
    with AutomaticKeepAliveClientMixin {
  late Stream<List<Community>> _myCommunities;
  late Stream<List<Community>> _joinedCommunities;

  void _navigateToCreateCommunityScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCommunityScreen(),
      ),
    );
  }

  void _navigateToModeratorScreen(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModToolsScreen(community: community),
      ),
    );
  }

  void _navigateToCommunityScreen(
    Community community,
    String uid,
  ) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
    final result = await ref
        .watch(moderationControllerProvider.notifier)
        .fetchMembershipStatus(
          getMembershipId(uid: uid, communityId: community.id),
        );

    result.fold(
      (l) {
        showToast(false, 'Unexpected error happened...');
      },
      (r) async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityScreen(
              communityId: community.id,
            ),
          ),
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _myCommunities =
        ref.watch(communityControllerProvider.notifier).getMyCommunities();
    _joinedCommunities =
        ref.watch(communityControllerProvider.notifier).getUserCommunities();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider)!;
    super.build(context);
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
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
                  _navigateToCreateCommunityScreen();
                },
              ).animate().fadeIn(),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ref.read(fetchCommunitiesProvider).when(
                      data: (communities) {
                        return DropdownSearch<Community>(
                          items: communities,
                          itemAsString: (Community community) => community.name,
                          onChanged: (Community? selectedCommunity) {
                            if (selectedCommunity != null) {
                              _navigateToCommunityScreen(
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
                                title: Text(item.name),
                                leading: CircleAvatar(
                                  backgroundImage: CachedNetworkImageProvider(
                                    item.profileImage,
                                  ),
                                ),
                              ).animate().fadeIn();
                            },
                          ),
                        ).animate().fadeIn();
                      },
                      error: (e, s) =>
                          ErrorText(error: e.toString()).animate().fadeIn(),
                      loading: () => const Loading().animate().fadeIn(),
                    ),
              ).animate().fadeIn(),
              const Divider(),
              const ListTile(
                title: Text(
                  'Moderation',
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
                child: StreamBuilder(
                    stream: _myCommunities,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Loading',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Loading(),
                          ].animate().fadeIn(duration: 600.ms).moveY(
                                begin: 30,
                                end: 0,
                                duration: 600.ms,
                                curve: Curves.easeOutBack,
                              ),
                        );
                      } else if (snapshot.hasError) {
                        return ErrorText(error: snapshot.error.toString())
                            .animate()
                            .fadeIn();
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
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
                        ).animate().fadeIn();
                      } else {
                        return ListView.separated(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (BuildContext context, int index) {
                            final community = snapshot.data![index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(
                                  community.profileImage,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    community.name,
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
                                _navigateToModeratorScreen(community);
                              },
                            );
                          },
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 3);
                          },
                        ).animate().fadeIn();
                      }
                    }),
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
              ).animate().fadeIn(),
              Expanded(
                child: StreamBuilder(
                    stream: _joinedCommunities,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Loading',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Loading(),
                          ].animate().fadeIn(duration: 600.ms).moveY(
                                begin: 30,
                                end: 0,
                                duration: 600.ms,
                                curve: Curves.easeOutBack,
                              ),
                        );
                      } else if (snapshot.hasError) {
                        return ErrorText(error: snapshot.error.toString())
                            .animate()
                            .fadeIn();
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
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
                        ).animate().fadeIn();
                      } else {
                        return ListView.separated(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (BuildContext context, int index) {
                            final community = snapshot.data![index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(
                                  community.profileImage,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    community.name,
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
                                  community,
                                  currentUser.uid,
                                );
                              },
                            );
                          },
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 3);
                          },
                        ).animate().fadeIn();
                      }
                    }),
              ).animate().fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}

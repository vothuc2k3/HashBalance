import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/community/screen/mod_tools/edit_community_screen.dart';
import 'package:hash_balance/theme/pallette.dart';

class MyCommunityScreen extends ConsumerStatefulWidget {
  final String name;

  const MyCommunityScreen({
    super.key,
    required this.name,
  });

  @override
  MyCommunityScreenState createState() => MyCommunityScreenState();
}

class MyCommunityScreenState extends ConsumerState<MyCommunityScreen> {
  @override
  void initState() {
    super.initState();
  }

  void joinCommunity(String uid, String communityName, WidgetRef ref,
      BuildContext communityScreenContext) async {
    final result = await ref
        .read(communityControllerProvider.notifier)
        .joinCommunity(uid, communityName);
    result.fold(
      (l) => showSnackBar(
        communityScreenContext,
        l.toString(),
      ),
      (r) => showMaterialBanner(
        communityScreenContext,
        r.toString(),
      ),
    );
  }

  void leaveCommunity(String uid, String communityName, WidgetRef ref,
      BuildContext communityScreenContext) async {
    final result = await ref
        .read(communityControllerProvider.notifier)
        .leaveCommunity(uid, communityName);
    result.fold(
      (l) => showSnackBar(
        communityScreenContext,
        l.toString(),
      ),
      (r) => showMaterialBanner(
        communityScreenContext,
        r.toString(),
      ),
    );
  }

  void navigateToModTools(String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCommunityScreen(
          name: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Scaffold(
      body: ref.watch(getCommunityByNameProvider(widget.name)).when(
            data: (community) {
              final joined = community.members.contains(user!.uid);
              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 150,
                      flexibleSpace: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              community.bannerImage,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return Container(
                                  width: double.infinity,
                                  height: 150,
                                  color: Colors.black,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            Align(
                              alignment: Alignment.topLeft,
                              child: CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(
                                    community.profileImage),
                                radius: 35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  community.name,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                !community.moderators.contains(user.uid)
                                    ? OutlinedButton(
                                        onPressed: joined
                                            ? () => leaveCommunity(
                                                  user.uid,
                                                  community.name,
                                                  ref,
                                                  context,
                                                )
                                            : () => joinCommunity(
                                                  user.uid,
                                                  community.name,
                                                  ref,
                                                  context,
                                                ),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 25),
                                        ),
                                        child: joined
                                            ? const Text(
                                                'Joined',
                                                style: TextStyle(
                                                  color: Pallete.whiteColor,
                                                ),
                                              )
                                            : const Text(
                                                'Join',
                                                style: TextStyle(
                                                  color: Pallete.whiteColor,
                                                ),
                                              ),
                                      )
                                    : OutlinedButton(
                                        onPressed: () =>
                                            navigateToModTools(widget.name),
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 25),
                                        ),
                                        child: const Text(
                                          'Mod Tools',
                                          style: TextStyle(
                                            color: Pallete.whiteColor,
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child:
                                  Text('${community.members.length} members'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: const Text(''),
              );
            },
            error: (error, stackTrace) => ErrorText(error: error.toString()),
            loading: () => const Loading(),
          ),
    );
  }
}

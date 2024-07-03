import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/community/screen/mod_tools/mod_tools_screen.dart';
import 'package:hash_balance/theme/pallette.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  final String _name;

  const CommunityScreen({
    super.key,
    required String name,
  }) : _name = name;

  @override
  CommunityScreenState createState() => CommunityScreenState();
}

class CommunityScreenState extends ConsumerState<CommunityScreen> {
  void _showConfirmationDialog(
    dynamic leaveCommunity,
    bool isModerator,
    String uid,
    String communityName,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you leaving?'),
          content: Text(
            isModerator
                ? 'You\'re moderator, make sure your choice!'
                : 'Do you want to leave this community?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                leaveCommunity();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void joinCommunity(
    String uid,
    String communityName,
  ) async {
    final result = await ref
        .read(communityControllerProvider.notifier)
        .joinCommunity(uid, communityName);
    result.fold(
      (l) => showSnackBar(
        context,
        l.toString(),
      ),
      (r) => showMaterialBanner(
        context,
        r.toString(),
      ),
    );
  }

  void leaveCommunity(
    String uid,
    String communityName,
  ) async {
    final result = await ref
        .read(communityControllerProvider.notifier)
        .leaveCommunity(uid, communityName);
    result.fold(
      (l) => showSnackBar(
        context,
        l.toString(),
      ),
      (r) => showMaterialBanner(
        context,
        r.toString(),
      ),
    );
  }

  void navigateToModToolsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModToolsScreen(name: widget._name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final community = ref.watch(getCommunityByNameProvider(widget._name));
    final memberCount =
        ref.watch(getCommunityMemberCountProvider(widget._name));
    final joined = ref.watch(getMemberStatusProvider(widget._name));
    final isModerator = ref.watch(getModeratorStatus(widget._name));
    return Scaffold(
      body: community.when(
        data: (community) {
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  actions: [
                    isModerator.when(
                      data: (isModerator) {
                        return isModerator
                            ? TextButton(
                                onPressed: () {
                                  navigateToModToolsScreen();
                                },
                                child: const Text(
                                  'Mod Tools',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null;
                      },
                      error: (error, stackTrace) =>
                          ErrorText(error: error.toString()),
                      loading: () => const Text('Loading...'),
                    )!,
                  ],
                  expandedHeight: 150,
                  flexibleSpace: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          community.bannerImage,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
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
                        isModerator.when(
                          data: (isModerator) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  community.name,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                joined.when(
                                  data: (joined) {
                                    return OutlinedButton(
                                      onPressed: joined
                                          ? () => _showConfirmationDialog(
                                                leaveCommunity,
                                                isModerator,
                                                user!.uid,
                                                community.name,
                                              )
                                          : () => joinCommunity(
                                              user!.uid, community.name),
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
                                    );
                                  },
                                  error: (error, stackTrace) =>
                                      ErrorText(error: error.toString()),
                                  loading: () => const Loading(),
                                )
                              ],
                            );
                          },
                          error: (error, stackTrace) =>
                              ErrorText(error: error.toString()),
                          loading: () => const Loading(),
                        ),
                        memberCount.when(
                          data: (count) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text('$count members'),
                            );
                          },
                          error: (error, stackTrace) =>
                              ErrorText(error: error.toString()),
                          loading: () => const Loading(),
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

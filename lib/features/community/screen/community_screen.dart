import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/community/screen/mod_tools/mod_tools_screen.dart';
import 'package:hash_balance/features/community/screen/post_container/post_container.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/theme/pallette.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  final Community _community;

  const CommunityScreen({
    super.key,
    required Community community,
  }) : _community = community;

  @override
  CommunityScreenState createState() => CommunityScreenState();
}

class CommunityScreenState extends ConsumerState<CommunityScreen> {
  void _showConfirmationDialog(
    dynamic leaveCommunity,
    bool isModerator,
    String uid,
    String communityId,
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
                leaveCommunity(uid, communityId);
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
    String communityId,
  ) async {
    final result = await ref
        .read(communityControllerProvider.notifier)
        .joinCommunity(uid, communityId);
    result.fold(
      (l) => showToast(
        false,
        l.toString(),
      ),
      (r) => showToast(
        true,
        r.toString(),
      ),
    );
  }

  void leaveCommunity(
    String uid,
    String communityId,
  ) async {
    final result = await ref
        .read(communityControllerProvider.notifier)
        .leaveCommunity(uid, communityId);
    result.fold(
      (l) => showToast(
        false,
        l.toString(),
      ),
      (r) => showToast(
        true,
        r.toString(),
      ),
    );
  }

  void navigateToModToolsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModToolsScreen(community: widget._community),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final memberCount =
        ref.watch(getCommunityMemberCountProvider(widget._community.id));
    final joined = ref.watch(getMemberStatusProvider(widget._community.id));
    final isModerator = ref.watch(getModeratorStatus(widget._community.id));
    final posts =
        ref.watch(fetchCommunityPostsProvider(widget._community.id));
    return Scaffold(
        body: NestedScrollView(
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
                      : const SizedBox.shrink();
                },
                error: (error, stackTrace) =>
                    ErrorText(error: error.toString()),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
            expandedHeight: 150,
            flexibleSpace: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    widget._community.bannerImage,
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
                          widget._community.profileImage),
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
                            '#=${widget._community.name}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          joined.when(
                            data: (joined) {
                              return OutlinedButton(
                                onPressed: joined
                                    ? () => _showConfirmationDialog(
                                          leaveCommunity,
                                          isModerator,
                                          user!.uid,
                                          widget._community.name,
                                        )
                                    : () => joinCommunity(
                                        user!.uid, widget._community.id),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
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
      body: posts.when(
        data: (posts) {
          if (posts == null || posts.isEmpty) {
            return const Center(
              child: Text('No posts available.'),
            );
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return ref.watch(getUserByUidProvider(post.uid)).when(
                    data: (user) {
                      return ref
                          .watch(getCommunityByIdProvider(post.communityId))
                          .when(
                            data: (community) {
                              if (community == null) {
                                return const ErrorText(
                                  error: 'Unexpected Error Happenned....',
                                );
                              }
                              return PostContainer(
                                user: user,
                                post: post,
                                community: community,
                              );
                            },
                            error: (error, stackTrace) => ErrorText(
                              error: error.toString(),
                            ),
                            loading: () => const Loading(),
                          );
                    },
                    error: (error, stackTrace) => ErrorText(
                      error: error.toString(),
                    ),
                    loading: () => const Loading(),
                  );
            },
          );
        },
        error: (error, stackTrace) => ErrorText(
          error: error.toString(),
        ),
        loading: () => const Loading(),
      ),
    ));
  }
}

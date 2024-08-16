import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/common/widgets/error_text.dart';
import 'package:hash_balance/core/common/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/mod_tools_screen.dart';
import 'package:hash_balance/features/community/screen/post_container/post_container.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_model.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  final Community _community;
  final Post? _pinnedPost;
  final String _memberStatus;

  const CommunityScreen({
    super.key,
    required Community community,
    required Post? pinnedPost,
    required String memberStatus,
  })  : _community = community,
        _pinnedPost = pinnedPost,
        _memberStatus = memberStatus;

  @override
  CommunityScreenState createState() => CommunityScreenState();
}

class CommunityScreenState extends ConsumerState<CommunityScreen> {
  String? tempMemberStatus;

  void _onJoinCommunity(
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
            ), (r) {
      showToast(true, r.toString());
      tempMemberStatus = 'member';
      setState(() {});
    });
  }

  void _leaveCommunity(
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
            ), (r) {
      showToast(true, r.toString());
      tempMemberStatus = '';
      setState(() {});
    });
  }

  void _navigateToModToolsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModToolsScreen(community: widget._community),
      ),
    );
  }

  @override
  void initState() {
    tempMemberStatus = widget._memberStatus;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider)!;
    final memberCount =
        ref.watch(getCommunityMemberCountProvider(widget._community.id));
    final posts = ref.watch(fetchCommunityPostsProvider(widget._community.id));
    bool isLoading = ref.watch(communityControllerProvider);
    return Scaffold(
      body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                actions: [
                  if (tempMemberStatus == 'moderator')
                    TextButton(
                      onPressed: () {
                        _navigateToModToolsScreen();
                      },
                      child: const Text(
                        'Mod Tools',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (tempMemberStatus == 'member')
                    ElevatedButton(
                      onPressed: isLoading
                          ? () {}
                          : () {
                              _leaveCommunity(
                                currentUser.uid,
                                widget._community.id,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const Loading()
                          : const Text(
                              'Leave Community',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  if (tempMemberStatus == '')
                    ElevatedButton(
                      onPressed: isLoading
                          ? () {}
                          : () {
                              _onJoinCommunity(
                                currentUser.uid,
                                widget._community.id,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const Loading()
                          : const Text(
                              'Join Community',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${widget._community.name}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
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
          body: CustomScrollView(
            slivers: [
              if (widget._pinnedPost != null)
                SliverToBoxAdapter(
                  child: ref
                      .watch(getUserByUidProvider(widget._pinnedPost!.uid))
                      .when(
                        data: (author) {
                          return PostContainer(
                            isMod: tempMemberStatus == 'moderator',
                            author: author,
                            post: widget._pinnedPost!,
                            community: widget._community,
                            isPinnedPost: true,
                          );
                        },
                        error: (error, stackTrace) => ErrorText(
                          error: error.toString(),
                        ),
                        loading: () => const Loading(),
                      ),
                ),
              posts.when(
                data: (posts) {
                  if (posts == null || posts.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Text('No posts available.'),
                      ),
                    );
                  }

                  final filteredPosts = widget._pinnedPost != null
                      ? posts
                          .where((post) => post.id != widget._pinnedPost!.id)
                          .toList()
                      : posts;

                  if (filteredPosts.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: SizedBox.shrink(),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = filteredPosts[index];
                        return ref.watch(getUserByUidProvider(post.uid)).when(
                              data: (author) {
                                return PostContainer(
                                  isMod: tempMemberStatus == 'moderator',
                                  author: author,
                                  post: post,
                                  community: widget._community,
                                  isPinnedPost: false,
                                );
                              },
                              error: (error, stackTrace) => ErrorText(
                                error: error.toString(),
                              ),
                              loading: () => const Loading(),
                            );
                      },
                      childCount: filteredPosts.length,
                    ),
                  );
                },
                error: (error, stackTrace) => SliverToBoxAdapter(
                  child: ErrorText(
                    error: error.toString(),
                  ),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Loading(),
                ),
              ),
            ],
          )),
    );
  }
}

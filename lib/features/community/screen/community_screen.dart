import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/community/screen/post_container/post_container.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/mod_tools_screen.dart';
import 'package:hash_balance/features/newsfeed/controller/newsfeed_controller.dart';
import 'package:hash_balance/features/post/screen/create_post_screen.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_data_model.dart';
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
  Future<List<PostDataModel>>? posts;

  _onJoinCommunity(
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

      SchedulerBinding.instance.addPostFrameCallback((_) {
        setState(() {
          tempMemberStatus = 'member';
        });
      });
    });
  }

  _leaveCommunity(
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
      SchedulerBinding.instance.addPostFrameCallback((_) {
        setState(() {
          tempMemberStatus = '';
        });
      });
    });
  }

  _navigateToModToolsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModToolsScreen(community: widget._community),
      ),
    );
  }

  _navigateToCreatePostScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          chosenCommunity: widget._community,
          isFromCommunityScreen: true,
        ),
      ),
    );
  }

  _showImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: Colors.black,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 16,
                      right: 16,
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      tempMemberStatus = widget._memberStatus;
      posts = ref
          .read(newsfeedControllerProvider)
          .getCommunityPosts(widget._community.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider)!;
    final memberCount =
        ref.watch(getCommunityMemberCountProvider(widget._community.id));
    bool isLoading = ref.watch(communityControllerProvider);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              actions: [
                if (tempMemberStatus == 'moderator')
                  TextButton(
                    onPressed: _navigateToModToolsScreen,
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
              flexibleSpace: InkWell(
                onTap: () => _showImage(widget._community.bannerImage),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: widget._community.bannerImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          height: 150,
                          color: Colors.black,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () =>
                              _showImage(widget._community.profileImage),
                          child: CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(
                                widget._community.profileImage),
                            radius: 35,
                          ),
                        ),
                        IconButton(
                          onPressed: _navigateToCreatePostScreen,
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                          tooltip: 'Create a new post',
                        ),
                      ],
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
                      data: (countt) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text('$countt members'),
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
            SliverToBoxAdapter(
              child: FutureBuilder<List<PostDataModel>>(
                future: posts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No posts available'));
                  }
                  final posts = snapshot.data!;
                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final postData = posts[index];
                      return PostContainer(
                        isMod: tempMemberStatus == 'moderator',
                        isPinnedPost: false,
                        author: postData.author,
                        post: postData.post,
                        community: postData.community,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

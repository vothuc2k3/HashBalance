import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';

import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/community/screen/community_conversation_screen.dart';
import 'package:hash_balance/features/community/screen/post_container/post_container.dart';
import 'package:hash_balance/features/invitation/controller/invitation_controller.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/invite_moderators_screen.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/mod_tools_screen.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/post/screen/create_post_screen.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/invitation_model.dart';
import 'package:hash_balance/models/post_model.dart';

final currentCommunityProvider = Provider<Community>((ref) {
  throw UnimplementedError('currentCommunityProvider not overridden');
});

class CommunityScreen extends ConsumerStatefulWidget {
  final Community _community;
  final String _memberStatus;

  const CommunityScreen({
    super.key,
    required Community community,
    required String memberStatus,
  })  : _community = community,
        _memberStatus = memberStatus;

  @override
  CommunityScreenState createState() => CommunityScreenState();
}

class CommunityScreenState extends ConsumerState<CommunityScreen> {
  String? tempMemberStatus;
  Future<List<PostDataModel>>? posts;
  Future<PostDataModel?>? pinnedPost;

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

  void _handlePinPost(Post post) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .pinPost(post: post);
    result.fold(
      (l) => showToast(false, l.message),
      (r) {
        setState(() {
          pinnedPost = ref
              .read(postControllerProvider.notifier)
              .getCommunityPinnedPost(widget._community);
          posts = ref
              .read(communityControllerProvider.notifier)
              .getCommunityPosts(widget._community.id);
        });
      },
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _handleUnpinPost(Post post) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
    final result =
        await ref.read(moderationControllerProvider.notifier).unPinPost(post);
    result.fold(
      (l) => showToast(false, l.message),
      (r) {
        setState(() {
          pinnedPost = ref
              .read(postControllerProvider.notifier)
              .getCommunityPinnedPost(widget._community);
          posts = ref
              .read(communityControllerProvider.notifier)
              .getCommunityPosts(widget._community.id);
        });
      },
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _handleInvitation(
      bool option, String? uid, Invitation invitation) async {
    switch (option) {
      case true:
        final result = await ref
            .read(communityControllerProvider.notifier)
            .joinCommunityAsModerator(uid!, widget._community.id);
        result.fold((l) => showToast(false, l.message), (r) async {
          showToast(true, 'Successfully become a Moderator!');
          final result = await ref
              .read(invitationControllerProvider)
              .deleteInvitation(invitation.id);
          result.fold((l) => showToast(false, l.message), (_) {});
        });
        break;
      case false:
        final result = await ref
            .read(invitationControllerProvider)
            .deleteInvitation(invitation.id);
        result.fold((l) => showToast(false, l.message), (_) {});
        break;
    }
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
      builder: (context) {
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

  void _showMemberMoreOptions() {
    showMenu<int>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 40, 0, 0),
      items: [
        const PopupMenuItem<int>(
          value: 0,
          child: ListTile(
            leading: Icon(Icons.group),
            title: Text('Go to Community Conversations'),
          ),
        ),
        if (tempMemberStatus == 'moderator')
          const PopupMenuItem<int>(
            value: 1,
            child: ListTile(
              leading: Icon(Icons.add_moderator_sharp),
              title: Text('Go to Moderator Screen'),
            ),
          ),
        if (tempMemberStatus == 'moderator')
          const PopupMenuItem<int>(
            value: 2,
            child: ListTile(
              leading: Icon(Icons.person_add),
              title: Text('Invite Friends to Join Moderation'),
            ),
          ),
        const PopupMenuItem<int>(
          value: 3,
          child: ListTile(
            leading: Icon(Icons.report),
            title: Text('Report Community'),
          ),
        ),
        const PopupMenuItem<int>(
          value: 4,
          child: ListTile(
            leading: Icon(Icons.block),
            title: Text('Block Community'),
          ),
        ),
        const PopupMenuItem<int>(
          value: 5,
          child: ListTile(
            leading: Icon(Icons.arrow_left),
            title: Text('Leave Community'),
          ),
        ),
      ],
    ).then(
      (value) {
        if (value != null) {
          switch (value) {
            case 0:
              _navigateToCommunityConversations();
              break;
            case 1:
              _navigateToModToolsScreen();
              break;
            case 2:
              _navigateToInviteModeratorsScreen();
              break;
            case 3:
              _reportCommunity();
              break;
            case 4:
              _blockCommunity();
              break;
            case 5:
              _leaveCommunity(
                ref.watch(userProvider)!.uid,
                ref.watch(currentCommunityProvider).id,
              );
          }
        }
      },
    );
  }

  void _showInvitationDetails(String uid, Invitation invitation) {
    ref.read(getUserDataProvider(invitation.senderUid)).when(
          data: (sender) {
            return showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Invitation Details'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(invitation.type),
                      Text('From: ${sender.name}'),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _handleInvitation(false, null, invitation);

                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red, // Refuse colord
                            ),
                            child: const Text('Refuse'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _handleInvitation(true, uid, invitation);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // Confirm color
                            ),
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn();
              },
            );
          },
          error: (e, s) =>
              ErrorText(error: e.toString()).animate().fadeIn(duration: 800.ms),
          loading: () => const Loading().animate().fadeIn(duration: 800.ms),
        );
  }

  void _navigateToCommunityConversations() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityConversationScreen(
          community: widget._community,
        ),
      ),
    );
  }

  void _navigateToInviteModeratorsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InviteModeratorsScreen(
          community: widget._community,
        ),
      ),
    );
  }

  void _reportCommunity() {}

  void _blockCommunity() {}

  Future<void> _onRefresh() async {
    posts = ref
        .read(communityControllerProvider.notifier)
        .getCommunityPosts(widget._community.id);
    pinnedPost = ref
        .read(postControllerProvider.notifier)
        .getCommunityPinnedPost(widget._community);
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      tempMemberStatus = widget._memberStatus;
      posts = ref
          .read(communityControllerProvider.notifier)
          .getCommunityPosts(widget._community.id);
      pinnedPost = ref
          .read(postControllerProvider.notifier)
          .getCommunityPinnedPost(widget._community);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider)!;
    final memberCount =
        ref.watch(getCommunityMemberCountProvider(widget._community.id));
    final invitaion = ref.watch(invitationProvider(widget._community.id));
    bool isLoading = ref.watch(communityControllerProvider);

    return ProviderScope(
      overrides: [
        currentCommunityProvider.overrideWithValue(widget._community),
      ],
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF000000),
                Color(0xFF0D47A1),
                Color(0xFF1976D2),
              ],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  actions: [
                    if (tempMemberStatus == 'moderator')
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: _showMemberMoreOptions,
                      ),
                    if (tempMemberStatus == 'member')
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: _showMemberMoreOptions,
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

                        //RENDER INVITATION
                        invitaion.when(
                          data: (invitation) {
                            if (invitation == null) {
                              return const SizedBox.shrink();
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: ElevatedButton(
                                  onPressed: () => _showInvitationDetails(
                                    currentUser.uid,
                                    invitation,
                                  ),
                                  style: ButtonStyle(
                                    backgroundColor:
                                        WidgetStateProperty.all(Colors.blue),
                                    foregroundColor:
                                        WidgetStateProperty.all(Colors.white),
                                    overlayColor:
                                        WidgetStateProperty.resolveWith(
                                      (states) {
                                        if (states
                                            .contains(WidgetState.pressed)) {
                                          return Colors.green.withOpacity(0.2);
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  child: const Text(
                                    'Pending Invitation',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn();
                            }
                          },
                          error: (e, s) =>
                              ErrorText(error: e.toString()).animate().fadeIn(),
                          loading: () => const Loading().animate().fadeIn(),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FutureBuilder<PostDataModel?>(
                    future: pinnedPost,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      final post = snapshot.data!;
                      return PostContainer(
                        isMod: tempMemberStatus == 'moderator',
                        isPinnedPost: true,
                        author: post.author,
                        post: post.post,
                        community: post.community,
                        onUnPinPost: _handleUnpinPost,
                      ).animate().fadeIn(duration: 800.ms);
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: FutureBuilder<List<PostDataModel>>(
                    future: posts,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      } else if (snapshot.connectionState ==
                          ConnectionState.waiting) {
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
                      } else if (snapshot.connectionState ==
                          ConnectionState.done) {
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
                              onPinPost: _handlePinPost,
                            ).animate().fadeIn(duration: 800.ms);
                          },
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

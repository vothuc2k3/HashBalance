import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';
import 'package:hash_balance/core/widgets/community_livestream_container.dart';

import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/community_controller.dart';
import 'package:hash_balance/features/community/screen/community_conversation_screen.dart';
import 'package:hash_balance/features/community/screen/community_member_screen.dart';
import 'package:hash_balance/features/community/screen/post_container/community_post_container.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/invitation/controller/invitation_controller.dart';
import 'package:hash_balance/features/livestream/controller/livestream_controller.dart';
import 'package:hash_balance/features/livestream/screen/livestream_screen.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/invite_moderators_screen.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/mod_tools_screen.dart';
import 'package:hash_balance/features/community/screen/post_container/community_poll_container.dart';
import 'package:hash_balance/features/community/screen/create_post_screen.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/invitation_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:tuple/tuple.dart';

final currentMembershipProvider = StateProvider<String?>((ref) => null);
final currentInvitationProvider = StateProvider<Invitation?>((ref) => null);

class CommunityScreen extends ConsumerStatefulWidget {
  final String _communityId;

  const CommunityScreen({
    super.key,
    required String communityId,
  }) : _communityId = communityId;

  @override
  CommunityScreenState createState() => CommunityScreenState();
}

class CommunityScreenState extends ConsumerState<CommunityScreen> {
  UserModel? _currentUser;
  List<PostDataModel> _loadedPosts = [];
  Community? currentCommunity;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentUser = ref.watch(userProvider);
    _loadMembership();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToCreatePostScreen() {
    if (currentCommunity != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreatePostScreen(
            chosenCommunity: currentCommunity!,
          ),
        ),
      );
    }
  }

  //MARK: - BUILD WIDGET
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider)!;
    final role = ref.watch(currentMembershipProvider);
    return Scaffold(
      floatingActionButton: role == 'member' || role == 'moderator'
          ? FloatingActionButton(
              onPressed: () => _navigateToCreatePostScreen(),
              child: const Icon(Icons.add),
            )
          : null,
      body: Container(
        color: ref.watch(preferredThemeProvider).first,
        child: ref.watch(communityByIdProvider(widget._communityId)).when(
              data: (community) {
                currentCommunity = community;
                return ref
                    .watch(currentUserRoleProvider(
                        Tuple2(currentUser.uid, widget._communityId)))
                    .when(
                      data: (memberModel) {
                        return CustomScrollView(
                          slivers: [
                            SliverAppBar(
                              actions: [
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () {
                                    if (role == 'moderator') {
                                      _showModeratorMoreOptions(community);
                                    } else if (role == 'member') {
                                      _showMemberMoreOptions(community);
                                    } else {
                                      _showStrangerMoreOptions(community);
                                    }
                                  },
                                ),
                              ],
                              expandedHeight: 150,
                              flexibleSpace: InkWell(
                                onTap: () => _handleBannerImageAction(
                                    community, role ?? ''),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: CachedNetworkImage(
                                        imageUrl: community.bannerImage,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          width: double.infinity,
                                          height: 150,
                                          color: Colors.black,
                                          child: const Center(
                                            child: Loading(),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: () =>
                                              _handleProfileImageAction(
                                                  community, role ?? ''),
                                          child: CircleAvatar(
                                            backgroundImage:
                                                CachedNetworkImageProvider(
                                              community.profileImage,
                                            ),
                                            radius: 35,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _onCreateLivestream(
                                              community, currentUser.uid),
                                          icon: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          ),
                                          tooltip: 'Create a new livestream',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          community.name,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    ref
                                        .watch(getCommunityMemberCountProvider(
                                            widget._communityId))
                                        .when(
                                          data: (countt) {
                                            return GestureDetector(
                                              onTap: () =>
                                                  _navigateToCommunityMembersScreen(
                                                      community),
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 10),
                                                child: Text('$countt members'),
                                              ),
                                            );
                                          },
                                          error: (error, stackTrace) =>
                                              ErrorText(
                                                  error: error.toString()),
                                          loading: () => const Loading(),
                                        ),

                                    //RENDER INVITATION
                                    ref
                                        .watch(invitationProvider(
                                            widget._communityId))
                                        .when(
                                          data: (invitation) {
                                            if (invitation == null) {
                                              return const SizedBox.shrink();
                                            } else {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 10),
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      _showInvitationDetails(
                                                    currentUser.uid,
                                                    invitation,
                                                  ),
                                                  style: ButtonStyle(
                                                    backgroundColor:
                                                        WidgetStateProperty.all(
                                                            Colors.blue),
                                                    foregroundColor:
                                                        WidgetStateProperty.all(
                                                            Colors.white),
                                                    overlayColor:
                                                        WidgetStateProperty
                                                            .resolveWith(
                                                      (states) {
                                                        if (states.contains(
                                                            WidgetState
                                                                .pressed)) {
                                                          return Colors.green
                                                              .withOpacity(0.2);
                                                        }
                                                        return null;
                                                      },
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Pending Invitation',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ).animate().fadeIn();
                                            }
                                          },
                                          error: (e, s) =>
                                              ErrorText(error: e.toString())
                                                  .animate()
                                                  .fadeIn(),
                                          loading: () => const Loading()
                                              .animate()
                                              .fadeIn(),
                                        ),
                                  ],
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: ref
                                  .watch(communityLivestreamProvider(
                                      widget._communityId))
                                  .when(
                                    data: (livestream) {
                                      if (livestream == null) {
                                        return const SizedBox.shrink();
                                      } else {
                                        return CommunityLivestreamContainer(
                                            livestream: livestream,
                                            uid: currentUser.uid);
                                      }
                                    },
                                    loading: () => const Loading(),
                                    error: (error, stackTrace) =>
                                        ErrorText(error: error.toString()),
                                  ),
                            ),
                            //MARK: - REGULAR POSTS
                            SliverToBoxAdapter(
                              child: ref
                                  .watch(communityPostsProvider(
                                      widget._communityId))
                                  .when(
                                    data: (posts) {
                                      _loadedPosts = posts;
                                      _loadedPosts.sort((a, b) {
                                        if (a.post.isPinned &&
                                            !b.post.isPinned) {
                                          return -1;
                                        } else if (!a.post.isPinned &&
                                            b.post.isPinned) {
                                          return 1;
                                        } else {
                                          return 0;
                                        }
                                      });
                                      if (_loadedPosts.isEmpty) {
                                        return Center(
                                          child: const Text(
                                            'No posts yet....',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white70,
                                            ),
                                          )
                                              .animate()
                                              .fadeIn(duration: 600.ms)
                                              .moveY(
                                                begin: 30,
                                                end: 0,
                                                duration: 600.ms,
                                                curve: Curves.easeOutBack,
                                              ),
                                        );
                                      } else {
                                        return ListView.builder(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemCount: _loadedPosts.length,
                                          itemBuilder: (context, index) {
                                            final post = _loadedPosts[index];
                                            if (!post.post.isPoll) {
                                              return CommunityPostContainer(
                                                isMod: ref.watch(
                                                        currentMembershipProvider) ==
                                                    'moderator',
                                                isPinnedPost:
                                                    post.post.isPinned,
                                                author: post.author!,
                                                post: post.post,
                                                community: community,
                                                onPinPost: _handlePinPost,
                                                onUnPinPost: _handleUnpinPost,
                                              ).animate().fadeIn();
                                            } else if (post.post.isPoll) {
                                              return PollContainer(
                                                author: post.author!,
                                                poll: post.post,
                                                communityId:
                                                    widget._communityId,
                                              ).animate().fadeIn();
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        );
                                      }
                                    },
                                    loading: () =>
                                        const Center(child: Loading())
                                            .animate()
                                            .fade(),
                                    error: (error, stackTrace) =>
                                        Text('Error: $error').animate().fade(),
                                  ),
                            )
                          ],
                        );
                      },
                      error: (error, stackTrace) =>
                          ErrorText(error: error.toString()),
                      loading: () => const Loading(),
                    );
              },
              error: (e, s) =>
                  ErrorText(error: e.toString()).animate().fadeIn(),
              loading: () => const SizedBox.shrink(),
            ),
      ),
    );
  }

  void _onJoinCommunity(Community community) async {
    if (community.containsExposureContents) {
      final bool? shouldJoin = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                '18+ Contents Warning',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'This community contains 18+ contents. Are you sure you want to join?',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'No',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Yes',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldJoin == false) {
        return;
      } else {
        final result = await ref
            .read(communityControllerProvider.notifier)
            .joinCommunity(_currentUser!.uid, widget._communityId);

        result.fold(
          (l) => showToast(false, l.toString()),
          (r) {
            showToast(true, r);
            _loadMembership();
          },
        );
      }
    } else {
      final result = await ref
          .read(communityControllerProvider.notifier)
          .joinCommunity(_currentUser!.uid, widget._communityId);
      result.fold(
        (l) => showToast(false, l.toString()),
        (r) {
          showToast(true, r);
          _loadMembership();
        },
      );
    }
  }

  void _leaveCommunity(String communityId) async {
    final bool? shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text('Leave Community'),
          content: const Text('Are you sure you want to leave this community?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.greenAccent),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Leave',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true) {
      final result = await ref
          .read(communityControllerProvider.notifier)
          .leaveCommunity(_currentUser!.uid, communityId);
      result.fold(
        (l) => showToast(false, l.toString()),
        (r) {
          showToast(true, r);
          _loadMembership();
        },
      );
    }
  }

  void _handlePinPost(Post post) async {
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .pinPost(post: post);
    result.fold(
      (l) => showToast(false, l.message),
      (_) {},
    );
  }

  void _handleUnpinPost(Post post) async {
    final result =
        await ref.read(moderationControllerProvider.notifier).unpinPost(post);
    result.fold(
      (l) => showToast(false, l.message),
      (_) {},
    );
  }

  void _handleInvitation(
    bool option,
    String? uid,
    Invitation invitation,
  ) async {
    switch (option) {
      case true:
        switch (invitation.type) {
          case Constants.moderatorInvitationType:
            final result = await ref
                .read(communityControllerProvider.notifier)
                .joinCommunityAsModerator(uid!, widget._communityId);
            result.fold((l) => showToast(false, l.message), (r) async {
              showToast(true, r);
              _loadMembership();
              final result = await ref
                  .read(invitationControllerProvider)
                  .deleteInvitation(invitation.id);
              result.fold((l) => showToast(false, l.message), (_) {});
            });
            break;
          case Constants.membershipInvitationType:
            final result = await ref
                .read(communityControllerProvider.notifier)
                .joinCommunity(uid!, widget._communityId);
            result.fold((l) => showToast(false, l.message), (r) async {
              showToast(true, r);
              _loadMembership();
              final result = await ref
                  .read(invitationControllerProvider)
                  .deleteInvitation(invitation.id);
              result.fold((l) => showToast(false, l.message), (_) {});
            });

            break;
        }
      case false:
        final result = await ref
            .read(invitationControllerProvider)
            .deleteInvitation(invitation.id);
        result.fold((l) => showToast(false, l.message), (_) {});
        break;
    }
    ref.invalidate(invitationProvider);
  }

  _navigateToModToolsScreen(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModToolsScreen(community: community),
      ),
    );
  }

  void _onCreateLivestream(Community community, String uid) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
    final result = await ref
        .read(livestreamControllerProvider)
        .createLivestream(
            communityId: community.id, content: '', uid: _currentUser!.uid);
    result.fold((l) => showToast(false, l.message), (r) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LivestreamScreen(
            livestream: r,
            uid: uid,
          ),
        ),
      );
    });
  }

  void _uploadProfileImage(Community community, XFile profileImageFile) async {
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .uploadProfileImage(community, File(profileImageFile.path));
    result.fold((l) => showToast(false, l.message), (_) {
      showToast(true, 'Upload profile image successfully');
    });
  }

  void _uploadBannerImage(Community community, XFile bannerImageFile) async {
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .uploadBannerImage(community, File(bannerImageFile.path));
    result.fold((l) => showToast(false, l.message), (_) {
      showToast(true, 'Upload banner image successfully');
    });
  }

  void _changeProfileImage(Community community) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 100,
                );
                if (image != null) {
                  _uploadProfileImage(community, image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _changeBannerImage(Community community) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await ImagePicker().pickImage(
                  source: ImageSource.gallery, // Chọn từ bộ nhớ
                  imageQuality: 100, // Giảm chất lượng ảnh để giảm dung lượng
                );
                if (image != null) {
                  _uploadBannerImage(community, image); // Xử lý ảnh
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () {
                Navigator.pop(context); // Đóng modal
              },
            ),
          ],
        );
      },
    );
  }

  void _handleProfileImageAction(Community community, String role) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: ref.watch(preferredThemeProvider).first,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View Profile Image'),
                onTap: () {
                  Navigator.pop(context);
                  showImage(context, community.profileImage);
                },
              ),
              if (role == 'moderator')
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Change Profile Image'),
                  onTap: () {
                    Navigator.pop(context);
                    _changeProfileImage(community);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleBannerImageAction(Community community, String role) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: ref.watch(preferredThemeProvider).first,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View Banner Image'),
                onTap: () {
                  Navigator.pop(context);
                  showImage(context, community.bannerImage);
                },
              ),
              if (role == 'moderator')
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Change Banner Image'),
                  onTap: () {
                    Navigator.pop(context);
                    _changeBannerImage(community);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStrangerMoreOptions(Community community) {
    showMenu<int>(
      color: ref.watch(preferredThemeProvider).second,
      context: context,
      position: const RelativeRect.fromLTRB(100, 40, 0, 0),
      items: [
        const PopupMenuItem<int>(
          value: 0,
          child: ListTile(
            leading: Icon(Icons.person_add),
            title: Text('Join Community'),
          ),
        ),
        const PopupMenuItem<int>(
          value: 1,
          child: ListTile(
            leading: Icon(Icons.report),
            title: Text('Report'),
          ),
        ),
        const PopupMenuItem<int>(
          value: 2,
          child: ListTile(
            leading: Icon(Icons.block),
            title: Text('Block'),
          ),
        ),
      ],
    ).then(
      (value) {
        if (value != null) {
          switch (value) {
            case 0:
              _onJoinCommunity(community);
              break;
            case 1:
              break;
            case 2:
              break;
          }
        }
      },
    );
  }

  void _showMemberMoreOptions(Community community) {
    showMenu<int>(
      color: ref.watch(preferredThemeProvider).second,
      context: context,
      position: const RelativeRect.fromLTRB(100, 40, 0, 0),
      items: [
        const PopupMenuItem<int>(
          value: 0,
          child: ListTile(
            leading: Icon(Icons.message),
            title: Text('Community Conversations'),
          ),
        ),
        const PopupMenuItem<int>(
          value: 1,
          child: ListTile(
            leading: Icon(Icons.person_add),
            title: Text('Invite Friends'),
          ),
        ),
        const PopupMenuItem<int>(
          value: 2,
          child: ListTile(
            leading: Icon(Icons.report),
            title: Text('Report'),
          ),
        ),
        const PopupMenuItem<int>(
          value: 3,
          child: ListTile(
            leading: Icon(Icons.block),
            title: Text('Block'),
          ),
        ),
        const PopupMenuItem<int>(
          value: 4,
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
              _navigateToCommunityConversations(community);
              break;
            case 1:
              _inviteFriends(community);
              break;
            case 2:
              _reportCommunity();
              break;
            case 3:
              _blockCommunity();
              break;
            case 4:
              _leaveCommunity(community.id);
              break;
          }
        }
      },
    );
  }

  void _showModeratorMoreOptions(Community community) {
    showMenu<int>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 40, 0, 0),
      items: [
        const PopupMenuItem<int>(
          value: 0,
          child: ListTile(
            leading: Icon(Icons.message),
            title: Text('Community Conversations'),
          ),
        ),
        const PopupMenuItem<int>(
          value: 1,
          child: ListTile(
            leading: Icon(Icons.add_moderator_sharp),
            title: Text('Moderator Tools'),
          ),
        ),
        const PopupMenuItem<int>(
          value: 2,
          child: ListTile(
            leading: Icon(Icons.person_add),
            title: Text('Invite Moderators'),
          ),
        ),
        const PopupMenuItem<int>(
          value: 3,
          child: ListTile(
            leading: Icon(Icons.arrow_left),
            title: Text('Leave Community'),
          ),
        ),
      ],
      color: ref.watch(preferredThemeProvider).second,
    ).then(
      (value) {
        if (value != null) {
          switch (value) {
            case 0:
              _navigateToCommunityConversations(community);
              break;
            case 1:
              _navigateToModToolsScreen(community);
              break;
            case 2:
              _navigateToInviteModeratorsScreen(community);
              break;
            case 3:
              _leaveCommunity(community.id);
              break;
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
                  backgroundColor: ref.watch(preferredThemeProvider).first,
                  title: const Text('Invitation Details'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(invitation.type == Constants.moderatorInvitationType
                          ? 'Moderator Invitation'
                          : 'Membership Invitation'),
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
                              backgroundColor: Colors.red,
                            ),
                            child: const Text(
                              'Refuse',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _handleInvitation(true, uid, invitation);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: const Text(
                              'Confirm',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn();
              },
            );
          },
          error: (e, s) => ErrorText(error: e.toString()).animate().fadeIn(),
          loading: () => const Loading().animate().fadeIn(),
        );
  }

  void _navigateToCommunityConversations(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityConversationScreen(
          community: community,
        ),
      ),
    );
  }

  void _inviteFriends(Community community) {
    showMaterialModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            return Container(
              color: ref.watch(preferredThemeProvider).first,
              child: ref.watch(fetchFriendsProvider(_currentUser!.uid)).when(
                    data: (friends) {
                      return FutureBuilder<List<String>>(
                        future: ref
                            .read(communityControllerProvider.notifier)
                            .getMembershipUids(widget._communityId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Loading().animate().fadeIn();
                          } else if (snapshot.hasError) {
                            return ErrorText(error: snapshot.error.toString());
                          } else {
                            final uids = snapshot.data ?? [];
                            final filteredFriends = friends
                                .where((friend) => !uids.contains(friend.uid))
                                .toList();
                            if (filteredFriends.isEmpty) {
                              return Center(
                                child: const Text(
                                  'No friends found...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                  ),
                                ).animate().fadeIn(duration: 600.ms).moveY(
                                      begin: 30,
                                      end: 0,
                                      duration: 600.ms,
                                      curve: Curves.easeOutBack,
                                    ),
                              );
                            }
                            return Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    'Invite Friends',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: filteredFriends.length,
                                    itemBuilder: (context, index) {
                                      final user = filteredFriends[index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage:
                                              CachedNetworkImageProvider(
                                                  user.profileImage),
                                        ),
                                        title: Text(user.name),
                                        trailing: ElevatedButton(
                                          onPressed: () {
                                            _inviteFriend(user.uid, user.name);
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: ref
                                                .watch(preferredThemeProvider)
                                                .approveButtonColor,
                                          ),
                                          child: const Text(
                                            'Invite',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      );
                    },
                    loading: () => const Loading().animate().fadeIn(),
                    error: (error, stack) => ErrorText(error: error.toString()),
                  ),
            );
          },
        );
      },
    );
  }

  void _navigateToInviteModeratorsScreen(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InviteModeratorsScreen(
          community: community,
        ),
      ),
    );
  }

  void _reportCommunity() {}

  void _blockCommunity() {}

  void _inviteFriend(String uid, String name) async {
    final result = await ref
        .read(invitationControllerProvider)
        .addMembershipInvitation(
            uid, widget._communityId, currentCommunity!.name);
    result.fold((l) => showToast(false, l.message), (r) {
      showToast(true, 'Invitation sent to $name!');
    });
  }

  void _loadMembership() async {
    final role = await ref
        .read(communityControllerProvider.notifier)
        .getMemberRole(_currentUser!.uid, widget._communityId);
    ref.read(currentMembershipProvider.notifier).update((state) => role);
  }

  void _navigateToCommunityMembersScreen(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityMembersScreen(community: community),
      ),
    );
  }
}

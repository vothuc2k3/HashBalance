import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/community/screen/community_conversation_screen.dart';
import 'package:hash_balance/features/community/screen/post_container/community_post_container.dart';
import 'package:hash_balance/features/invitation/controller/invitation_controller.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/invite_moderators_screen.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/mod_tools_screen.dart';
import 'package:hash_balance/features/community/screen/post_container/community_poll_container.dart';
import 'package:hash_balance/features/post/screen/create_post_screen.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/invitation_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:image_picker/image_picker.dart';

final currentCommunityProvider = Provider<Community>((ref) {
  throw UnimplementedError('currentCommunityProvider not overridden');
});

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
  Future<PostDataModel?>? pinnedPost;
  UserModel? _currentUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentUser = ref.watch(userProvider);
  }

  //MARK: - BUILD WIDGET
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider)!;
    final memberCount =
        ref.watch(getCommunityMemberCountProvider(widget._communityId));
    final invitaion = ref.watch(invitationProvider(widget._communityId));
    final memberModel = ref.watch(currentUserRoleProvider(widget._communityId));
    return Scaffold(
      body: Container(
        color: ref.watch(preferredThemeProvider).first,
        child: ref.watch(communityByIdProvider(widget._communityId)).when(
              data: (community) {
                return memberModel.when(
                  data: (memberModel) {
                    final String role = memberModel?.role ?? '';
                    return CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {
                                switch (role) {
                                  case 'moderator':
                                    _showModeratorMoreOptions(community);
                                    break;
                                  case 'member':
                                    _showMemberMoreOptions(community);
                                    break;
                                  default:
                                    _showStrangerMoreOptions();
                                    break;
                                }
                              },
                            ),
                          ],
                          expandedHeight: 150,
                          flexibleSpace: InkWell(
                            onTap: () => _handleBannerImageAction(community),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CachedNetworkImage(
                                    imageUrl: community.bannerImage,
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
                                      onTap: () => _handleProfileImageAction(
                                          community, role),
                                      child: CircleAvatar(
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                          community.profileImage,
                                        ),
                                        radius: 35,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _navigateToCreatePostScreen(
                                              community),
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
                                                WidgetStateProperty.resolveWith(
                                              (states) {
                                                if (states.contains(
                                                    WidgetState.pressed)) {
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
                                      ErrorText(error: e.toString())
                                          .animate()
                                          .fadeIn(),
                                  loading: () =>
                                      const Loading().animate().fadeIn(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        //MARK: - REGULAR POSTS
                        SliverToBoxAdapter(
                          child: ref
                              .watch(
                                  communityPostsProvider(widget._communityId))
                              .when(
                                data: (posts) {
                                  if (posts.isEmpty) {
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
                                      itemCount: posts.length,
                                      itemBuilder: (context, index) {
                                        final post = posts[index];

                                        if (!post.post.isPoll) {
                                          return PostContainer(
                                            isMod: role == 'moderator',
                                            isPinnedPost: post.post.isPinned,
                                            author: post.author!,
                                            post: post.post,
                                            communityId: widget._communityId,
                                            communityName: community.name,
                                            onPinPost: _handlePinPost,
                                            onUnPinPost: _handleUnpinPost,
                                          ).animate().fadeIn();
                                        } else if (post.post.isPoll) {
                                          return PollContainer(
                                            author: post.author!,
                                            poll: post.post,
                                            communityId: widget._communityId,
                                          ).animate().fadeIn();
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    );
                                  }
                                },
                                loading: () => const Center(child: Loading())
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

  void _onJoinCommunity() async {
    final result = await ref
        .read(communityControllerProvider.notifier)
        .joinCommunity(_currentUser!.uid, widget._communityId);
    result.fold(
        (l) => showToast(
              false,
              l.toString(),
            ), (r) {
      showToast(true, r.toString());
    });
  }

  void _leaveCommunity(String communityId) async {
    final result = await ref
        .read(communityControllerProvider.notifier)
        .leaveCommunity(_currentUser!.uid, communityId);
    result.fold(
        (l) => showToast(
              false,
              l.toString(),
            ), (r) {
      showToast(true, r.toString());
    });
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
      bool option, String? uid, Invitation invitation) async {
    switch (option) {
      case true:
        final result = await ref
            .read(communityControllerProvider.notifier)
            .joinCommunityAsModerator(uid!, widget._communityId);
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

  _navigateToModToolsScreen(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModToolsScreen(community: community),
      ),
    );
  }

  _navigateToCreatePostScreen(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          chosenCommunity: community,
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
                  source: ImageSource.gallery, // Chọn từ bộ nhớ
                  imageQuality: 100, // Giảm chất lượng ảnh để giảm dung lượng
                );
                if (image != null) {
                  _uploadProfileImage(community, image); // Xử lý ảnh
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile Image'),
              onTap: () {
                Navigator.pop(context);
                _showImage(community.profileImage);
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
        );
      },
    );
  }

  void _handleBannerImageAction(Community community) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Banner Image'),
              onTap: () {
                Navigator.pop(context);
                _showImage(community.bannerImage);
              },
            ),
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
        );
      },
    );
  }

  void _showStrangerMoreOptions() {
    showMenu<int>(
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
              _onJoinCommunity();
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
      context: context,
      position: const RelativeRect.fromLTRB(100, 40, 0, 0),
      items: [
        const PopupMenuItem<int>(
          value: 0,
          child: ListTile(
            leading: Icon(Icons.person_add),
            title: Text('Community Conversations'),
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
        const PopupMenuItem<int>(
          value: 3,
          child: ListTile(
            leading: Icon(Icons.block),
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
              _reportCommunity();
              break;
            case 2:
              _blockCommunity();
              break;
            case 3:
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
}

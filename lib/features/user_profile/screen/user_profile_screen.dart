import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hash_balance/features/theme/controller/theme_controller.dart';
import 'package:hash_balance/features/user_profile/screen/widget/user_timeline_widget.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:image_picker/image_picker.dart';

import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/user_profile/screen/friends/friend_requests_screen.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/models/user_model.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UserProfileScreenScreenState();
}

class _UserProfileScreenScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final double coverHeight = 250;
  final double profileHeight = 120;
  late PageController _pageController;
  int _currentIndex = 0;
  late Future<List<PostDataModel>> _userPosts;

  void _navigateToFriendRequestsScreen(String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendRequestsScreen(uid: uid),
      ),
    );
  }

  void _navigateToFriendProfile(UserModel friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(targetUser: friend),
      ),
    );
  }

  void _uploadProfileImage(
      UserModel currentUser, XFile profileImageFile) async {
    final result = await ref
        .read(userControllerProvider.notifier)
        .uploadProfileImage(currentUser, File(profileImageFile.path));
    result.fold((l) => showToast(false, l.message), (r) {
      showToast(true, 'Upload profile image successfully');
    });
  }

  void _uploadBannerImage(UserModel currentUser, XFile bannerImageFile) async {
    final result = await ref
        .read(userControllerProvider.notifier)
        .uploadBannerImage(currentUser, File(bannerImageFile.path));
    result.fold((l) => showToast(false, l.message), (r) {
      showToast(true, 'Upload banner image successfully');
    });
  }

  void _editName(UserModel currentUser, String name) async {
    if (name.isEmpty || name.length < 3) {
      showToast(false, 'Name must be at least 3 characters');
    } else if (name.length > 15) {
      showToast(false, 'Name must be less than 15 characters');
    } else {
      final result = await ref
          .read(userControllerProvider.notifier)
          .editName(currentUser, name);
      result.fold(
        (l) => showToast(false, l.message),
        (r) {
          showToast(true, 'Edit name successfully');
        },
      );
    }
  }

  void _editBio(UserModel currentUser, String bio) async {
    if (bio.isEmpty) {
      showToast(false, 'Bio must be at least 1 characters');
    } else if (bio.length > 100) {
      showToast(false, 'Bio must be less than 100 characters');
    } else {
      final result = await ref
          .read(userControllerProvider.notifier)
          .editBio(currentUser, bio);
      result.fold(
        (l) => showToast(false, l.message),
        (r) {
          showToast(true, 'Edit bio successfully');
        },
      );
    }
  }

  void _editDescription(UserModel currentUser, String description) async {
    if (description.isEmpty) {
      showToast(false, 'Description must be at least 1 characters');
    } else if (description.length > 100) {
      showToast(false, 'Description must be less than 100 characters');
    } else {
      final result = await ref
          .read(userControllerProvider.notifier)
          .editDescription(currentUser, description);
      result.fold(
        (l) => showToast(false, l.message),
        (r) {
          showToast(true, 'Edit description successfully');
        },
      );
    }
  }

  void _showEditNameModal(UserModel currentUser) async {
    final nameController = TextEditingController();
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
              leading: const Icon(Icons.edit),
              title: const Text('Edit Name'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Edit Name'),
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your new name',
                        ),
                      ),
                    );
                  },
                );
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

  void _showEditBioModal(UserModel currentUser) async {
    final bioController = TextEditingController();
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
              leading: const Icon(Icons.edit),
              title: const Text('Edit Bio'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Edit Name'),
                      content: TextField(
                        controller: bioController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your new bio',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _editBio(currentUser, bioController.text);
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            minimumSize: const Size(80, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
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

  void _showEditDescriptionModal(UserModel currentUser) async {
    final descriptionController = TextEditingController();
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
              leading: const Icon(Icons.edit),
              title: const Text('Edit Bio'),
              onTap: () {
                Navigator.pop(context); // Đóng modal
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Edit Description'),
                      content: TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your new description',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            _editDescription(
                                currentUser, descriptionController.text);
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            minimumSize: const Size(80, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
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

  void _changeProfileImage(UserModel currentUser) async {
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
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(context); // Đóng modal
                final XFile? image = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  imageQuality: 100,
                );
                if (image != null) {
                  _uploadProfileImage(currentUser, image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context); // Đóng modal
                final XFile? image = await ImagePicker().pickImage(
                  source: ImageSource.gallery, // Chọn từ bộ nhớ
                  imageQuality: 100, // Giảm chất lượng ảnh để giảm dung lượng
                );
                if (image != null) {
                  _uploadProfileImage(currentUser, image); // Xử lý ảnh
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

  void _changeBannerImage(UserModel currentUser) async {
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
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () async {
                Navigator.pop(context); // Đóng modal
                final XFile? image = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  imageQuality: 100,
                );
                if (image != null) {
                  _uploadBannerImage(currentUser, image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(context); // Đóng modal
                final XFile? image = await ImagePicker().pickImage(
                  source: ImageSource.gallery, // Chọn từ bộ nhớ
                  imageQuality: 100, // Giảm chất lượng ảnh để giảm dung lượng
                );
                if (image != null) {
                  _uploadBannerImage(currentUser, image); // Xử lý ảnh
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

  void _showImage(String imageUrl) {
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

  void _handleProfileImageAction(UserModel currentUser) async {
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
                _showImage(currentUser.profileImage);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Change Profile Image'),
              onTap: () {
                Navigator.pop(context);
                _changeProfileImage(currentUser);
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

  void _handleBannerImageAction(UserModel currentUser) async {
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
                _showImage(currentUser.bannerImage);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Change Banner Image'),
              onTap: () {
                Navigator.pop(context);
                _changeBannerImage(currentUser);
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

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onBottomNavTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUser = ref.read(userProvider)!;
    _userPosts =
        ref.read(userControllerProvider.notifier).getUserPosts(currentUser);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double top = coverHeight - profileHeight / 2;
    final double bottom = profileHeight / 2;
    final currentUser = ref.watch(userProvider)!;
    var userProfileData = ref.watch(userProfileDataProvider(currentUser.uid));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications,
                  color: Colors.white,
                ),
              ),
              Positioned(
                right: 11,
                top: 11,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '6',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          //MARK: - User Profile Widget
          RefreshIndicator(
            onRefresh: () async {
              userProfileData =
                  ref.refresh(userProfileDataProvider(currentUser.uid));
            }, // Hàm làm mới
            child: Container(
              decoration: BoxDecoration(
                color: ref.watch(preferredThemeProvider),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: bottom),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        InkWell(
                          onTap: () => _handleBannerImageAction(currentUser),
                          child: CachedNetworkImage(
                            imageUrl: currentUser.bannerImage,
                            width: double.infinity,
                            height: coverHeight,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: top,
                          left: 10,
                          child: InkWell(
                            onTap: () => _handleProfileImageAction(currentUser),
                            child: CircleAvatar(
                              radius: (profileHeight / 2) - 10,
                              backgroundColor: Colors.grey.shade800,
                              backgroundImage: CachedNetworkImageProvider(
                                currentUser.profileImage,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Text(
                                    '#${currentUser.name}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.9),
                                      shadows: const [
                                        Shadow(
                                          offset: Offset(1.5, 1.5),
                                          blurRadius: 3.0,
                                          color: Colors.black26,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: InkWell(
                                      onTap: () =>
                                          _showEditNameModal(currentUser),
                                      child: const Icon(Icons.edit),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Text(
                                    currentUser.bio ??
                                        'You haven\'t said anything yet...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.8),
                                      shadows: const [
                                        Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 2.0,
                                          color: Colors.black12,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: InkWell(
                                      onTap: () =>
                                          _showEditBioModal(currentUser),
                                      child: const Icon(Icons.edit),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  Text(
                                    currentUser.description ??
                                        'You haven\'t described yourself yet...',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      letterSpacing: 0.5,
                                      height: 1.4,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0.5, 0.5),
                                          blurRadius: 1.0,
                                          color: Colors.black12,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: InkWell(
                                      onTap: () => _showEditDescriptionModal(
                                          currentUser),
                                      child: const Icon(Icons.edit),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildSocialIcon(FontAwesomeIcons.slack),
                            const SizedBox(width: 12),
                            _buildSocialIcon(FontAwesomeIcons.github),
                            const SizedBox(width: 12),
                            _buildSocialIcon(FontAwesomeIcons.twitter),
                            const SizedBox(width: 12),
                            _buildSocialIcon(FontAwesomeIcons.linkedin),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      userProfileData.when(
                        data: (data) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAnimatedButton(
                                text: 'Friends',
                                oldValue: 0,
                                newValue: data.friends.length,
                                onPressed: () =>
                                    _navigateToFriendRequestsScreen(
                                        currentUser.uid),
                              ),
                              _buildVerticalDivider(),
                              _buildAnimatedButton(
                                text: 'Followers',
                                oldValue: 0,
                                newValue: data.followers.length,
                                onPressed: () {},
                              ),
                              _buildVerticalDivider(),
                              _buildAnimatedButton(
                                text: 'Following',
                                oldValue: 0,
                                newValue: data.following.length,
                                onPressed: () {},
                              ),
                              _buildVerticalDivider(),
                              _buildAnimatedButton(
                                text: 'Points',
                                oldValue: 0,
                                newValue: currentUser.activityPoint,
                                onPressed: () {},
                              ),
                            ],
                          );
                        },
                        loading: () {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildButton(
                                text: 'Friends',
                                value: 0,
                                onPressed: () =>
                                    _navigateToFriendRequestsScreen(
                                        currentUser.uid),
                              ),
                              _buildVerticalDivider(),
                              _buildButton(
                                text: 'Followers',
                                value: 0,
                                onPressed: () {},
                              ),
                              _buildVerticalDivider(),
                              _buildButton(
                                text: 'Following',
                                value: 0,
                                onPressed: () {},
                              ),
                              _buildVerticalDivider(),
                              _buildButton(
                                text: 'Activity Points',
                                value: 0,
                                onPressed: () {},
                              ),
                            ],
                          );
                        },
                        error: (error, stackTrace) => Text('Error: $error'),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildFriendsWidget(currentUser.uid),
                    ],
                  )
                ],
              ),
            ),
          ),
          //MARK: - User Timeline Widget
          UserTimelineWidget(userPostsFuture: _userPosts),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dynamic_feed),
            label: 'Timeline',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return CircleAvatar(
      radius: 25,
      child: Material(
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Center(
            child: Icon(
              icon,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required Function() onPressed,
    required String text,
    required int oldValue,
    required int newValue,
  }) {
    return Expanded(
      child: MaterialButton(
        padding: const EdgeInsets.symmetric(vertical: 4),
        onPressed: onPressed,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Text(
                '$newValue',
                key: ValueKey<int>(newValue),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required Function() onPressed,
    required String text,
    required int value,
  }) {
    return Expanded(
      child: MaterialButton(
        padding: const EdgeInsets.symmetric(vertical: 4),
        onPressed: onPressed,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return const VerticalDivider(
      width: 0.1,
      thickness: 1,
      color: Colors.grey,
    );
  }

  Widget _buildFriendsWidget(String uid) {
    return ref.watch(fetchFriendsProvider(uid)).when(
          data: (friendList) {
            if (friendList.isEmpty) {
              return const SizedBox.shrink();
            } else {
              return Column(
                children: [
                  SizedBox(
                    height: 250,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: friendList.length,
                      itemBuilder: (context, index) {
                        final friend = friendList[index];
                        return Column(
                          children: [
                            InkWell(
                              onTap: () => _navigateToFriendProfile(friend),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundImage: CachedNetworkImageProvider(
                                  friend.profileImage,
                                ),
                                child: friend.profileImage.isEmpty
                                    ? const Icon(Icons.error)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              friend.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5, // Tạo hiệu ứng nổi cho nút
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.black
                            .withOpacity(0.25), // Hiệu ứng shadow mượt hơn
                      ).copyWith(
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                      ),
                      onPressed: () {},
                      child: Ink(
                        decoration: BoxDecoration(
                          color: Colors
                              .blueAccent, // Thay đổi từ gradient sang màu duy nhất
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          constraints: const BoxConstraints(minHeight: 50),
                          child: const Text(
                            'See all friends',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 3),
                                  blurRadius: 6.0,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              );
            }
          },
          error: (error, stackTrace) => Center(
            child: Text(
              'Error: $error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        );
  }
}

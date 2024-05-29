import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:routemaster/routemaster.dart';

class EditUserProfileScreen extends ConsumerStatefulWidget {
  final String uid;

  const EditUserProfileScreen({
    super.key,
    required this.uid,
  });

  @override
  EditUserProfileScreenState createState() => EditUserProfileScreenState();
}

class EditUserProfileScreenState extends ConsumerState<EditUserProfileScreen> {
  File? bannerImageFile;
  File? profileImageFile;
  String? name;
  String? bio;
  String? description;

  void selectBannerImage() async {
    final result = await pickImage();
    if (result != null) {
      setState(() {
        bannerImageFile = File(result.files.first.path!);
      });
    }
  }

  void selectProfileImage() async {
    final result = await pickImage();
    if (result != null) {
      setState(() {
        profileImageFile = File(result.files.first.path!);
      });
    }
  }

  void setName() {}

  void setBio() {}

  void setDescription() {}

  void saveChanges(UserModel user) async {
    final result = await ref
        .read(userControllerProvider.notifier)
        .editUserProfile(
            user, profileImageFile, bannerImageFile, name, bio, description);
    result.fold((l) => showSnackBar(context, l.toString()),
        (r) => showMaterialBanner(context, r.toString()));
  }

  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            width: 40,
            color: Colors.grey,
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          ListTile(
              leading: const Icon(Icons.change_circle_rounded),
              title: const Text('Name'),
              subtitle: const Text('Make a change for your displaying name'),
              onTap: () {
                setName();
                Navigator.pop(context);
              }),
          ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Bio'),
              subtitle: const Text('Click here to refine your bio'),
              onTap: () {
                setBio();
                Navigator.pop(context);
              }),
          ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Description'),
              subtitle: const Text('Enhance your profile details'),
              onTap: () {
                setDescription();
                Navigator.pop(context);
              }),
          ListTile(
              leading: const Icon(Icons.add_a_photo),
              title: const Text('Profile Image'),
              subtitle: const Text('Refresh your profile look'),
              onTap: () {
                selectProfileImage();
                Navigator.pop(context);
              }),
          ListTile(
              leading: const Icon(Icons.add_photo_alternate),
              title: const Text('Banner Image'),
              subtitle: const Text('Change your banner photo'),
              onTap: () {
                selectBannerImage();
                Navigator.pop(context);
              }),
        ],
      ),
    );
  }

  @override
  void initState() => super.initState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ref.watch(getUserDataProvider(widget.uid)).when(
            data: (user) => NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    actions: [
                      TextButton(
                        onPressed: () => saveChanges(user),
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Pallete.whiteColor),
                        ),
                      ),
                    ],
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Routemaster.of(context).push('/user-profile/${widget.uid}');
                      },
                    ),
                    expandedHeight: 250,
                    floating: true,
                    snap: true,
                    flexibleSpace: Stack(
                      children: [
                        Positioned.fill(
                          child: bannerImageFile != null
                              ? Image.file(bannerImageFile!)
                              : Image.network(
                                  user.bannerImage,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Container(
                          alignment: Alignment.bottomLeft,
                          padding:
                              const EdgeInsets.all(20).copyWith(bottom: 70),
                          child: CircleAvatar(
                            backgroundImage: profileImageFile != null
                                ? FileImage(profileImageFile!) as ImageProvider
                                : NetworkImage(user.profileImage),
                            radius: 45,
                          ),
                        ),
                        Container(
                          alignment: Alignment.bottomLeft,
                          padding: const EdgeInsets.all(20),
                          child: OutlinedButton(
                            onPressed: () => _showEditProfileModal(),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25),
                            ),
                            child: const Text(
                              'Edit Profile',
                              style: TextStyle(color: Pallete.whiteColor),
                            ),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'u/${user.name}',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(thickness: 2),
                          const SizedBox(height: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.bio ?? 'No bio provided yet.',
                                style: TextStyle(
                                  color: user.bio != null
                                      ? Colors.black
                                      : Colors.grey,
                                  fontStyle: user.bio != null
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                user.bio ?? 'No description provided yet.',
                                style: TextStyle(
                                  color: user.bio != null
                                      ? Colors.black
                                      : Colors.grey,
                                  fontStyle: user.bio != null
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: const SizedBox(),
            ),
            error: (error, stackTrace) => ErrorText(error: error.toString()),
            loading: () => const Loading(),
          ),
    );
  }
}

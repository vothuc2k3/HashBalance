import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/theme/pallette.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final UserModel currentUser;
  const EditProfileScreen({
    super.key,
    required this.currentUser,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  File? bannerImageFile;
  File? profileImageFile;

  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final descController = TextEditingController();

  bool isSetting = false;

  bool isNameValid = true;

  void setting() {
    setState(() {
      isSetting = true;
    });
  }

  void selectBannerImage() async {
    final result = await pickImage();
    if (result != null) {
      setState(() {
        bannerImageFile = File(result.files.first.path!);
        isSetting = false;
      });
    }
  }

  void checkName(String name, String uid) async {
    if (name.length < 5) {
      setState(() {
        isNameValid = false;
      });
      return;
    }

    final result = await checkExistingUserName(name, uid);
    result.fold((l) {}, (r) {
      setState(() {
        isNameValid = r;
      });
    });
  }

  void selectProfileImage() async {
    final result = await pickImage();
    if (result != null) {
      setState(() {
        profileImageFile = File(result.files.first.path!);
        isSetting = false;
      });
    }
  }

  void saveChanges(UserModel user) async {
    FocusScope.of(context).unfocus;
    final result =
        await ref.read(userControllerProvider.notifier).editUserProfile(
              user,
              profileImageFile,
              bannerImageFile,
              nameController.text.trim() == ''
                  ? user.name
                  : nameController.text.trim(),
              bioController.text.trim() == ''
                  ? user.bio
                  : bioController.text.trim(),
              descController.text.trim() == ''
                  ? user.description
                  : descController.text.trim(),
            );
    result.fold((l) => showToast(false, l.toString()),
        (r) => showToast(true, r.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: isSetting
          ? const Loading()
          : Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                title: const Text('Edit Profile'),
                centerTitle: false,
                actions: [
                  TextButton(
                    onPressed: () {
                      if (isNameValid) {
                        saveChanges(widget.currentUser);
                      }
                    },
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Pallete.whiteColor),
                    ),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: Stack(
                          children: [
                            DottedBorder(
                              borderType: BorderType.RRect,
                              radius: const Radius.circular(40),
                              dashPattern: const [10, 4],
                              strokeCap: StrokeCap.round,
                              color: Pallete.darkModeAppTheme.textTheme
                                  .bodyMedium!.color!,
                              child: Container(
                                width: double.infinity,
                                height: 150,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: InkWell(
                                  radius: 40.0,
                                  onTap: () {
                                    selectBannerImage();
                                  },
                                  child: bannerImageFile != null
                                      ? Image.file(bannerImageFile!)
                                      : widget.currentUser.bannerImage ==
                                              Constants.bannerDefault
                                          ? const Center(
                                              child: Icon(
                                                Icons.camera_alt_outlined,
                                                size: 40,
                                              ),
                                            )
                                          : Image.network(
                                              widget.currentUser.bannerImage,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return Container(
                                                  width: double.infinity,
                                                  height: 150,
                                                  color: Colors.black,
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                );
                                              },
                                            ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 20,
                              left: 20,
                              child: InkWell(
                                onTap: () {
                                  selectProfileImage();
                                },
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: profileImageFile != null
                                      ? FileImage(profileImageFile!)
                                      : !(Constants.avatarDefault.contains(
                                              widget.currentUser.profileImage))
                                          ? CachedNetworkImageProvider(widget
                                              .currentUser
                                              .profileImage) as ImageProvider
                                          : null,
                                  child: Constants.avatarDefault.contains(
                                          widget.currentUser.profileImage)
                                      ? const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 30,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 3),
                          //Start of Name input text field
                          const Padding(
                            padding: EdgeInsets.only(left: 10, bottom: 10),
                            child: Text(
                              'Name',
                              style: TextStyle(
                                  fontSize: 15, fontStyle: FontStyle.italic),
                            ),
                          ),
                          const SizedBox(height: 3),
                          TextField(
                            controller: nameController,
                            keyboardType: TextInputType.text,
                            autocorrect: false,
                            maxLength: 15,
                            decoration: InputDecoration(
                              labelText: 'Enter your name',
                              labelStyle: const TextStyle(
                                color: Color(0xFF38464E),
                              ),
                              hintText: widget.currentUser.name,
                              prefixText: '#',
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: isNameValid ? Colors.grey : Colors.red,
                                ),
                              ),
                              errorText: isNameValid ? null : 'Invalid name',
                            ),
                            onChanged: (value) {
                              checkName(value, widget.currentUser.uid);
                            },
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9]'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          //Start of Bio input text field
                          const Padding(
                            padding: EdgeInsets.only(left: 10, bottom: 10),
                            child: Text(
                              'Bio',
                              style: TextStyle(
                                  fontSize: 15, fontStyle: FontStyle.italic),
                            ),
                          ),
                          const SizedBox(height: 3),
                          TextField(
                            controller: bioController,
                            keyboardType: TextInputType.text,
                            autocorrect: false,
                            maxLength: 50,
                            decoration: InputDecoration(
                              labelText: 'Enter your bio',
                              labelStyle: const TextStyle(
                                color: Color(0xFF38464E),
                              ),
                              hintText: 'I\'m the best gamer ever lived....',
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: isNameValid ? Colors.grey : Colors.red,
                                ),
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 10),
                          const Divider(),
                          //Start of Description input text field
                          const Padding(
                            padding: EdgeInsets.only(left: 10, bottom: 10),
                            child: Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          TextField(
                            controller: descController,
                            keyboardType: TextInputType.text,
                            autocorrect: false,
                            maxLength: 100,
                            decoration: const InputDecoration(
                              labelText: 'Enter your description',
                              labelStyle: TextStyle(
                                color: Color(0xFF38464E),
                              ),
                              hintText:
                                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam risus justo, auctor non libero eget, pharetra suscipit leo. Nam posuere, nisl nec faucibus mattis, lacus quam tincidunt lacus....',
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

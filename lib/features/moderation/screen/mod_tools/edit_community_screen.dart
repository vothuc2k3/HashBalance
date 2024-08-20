import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/theme/pallette.dart';

class EditCommunityScreen extends ConsumerStatefulWidget {
  final String id;
  const EditCommunityScreen({
    super.key,
    required this.id,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EditCommunityScreenState();
}

class _EditCommunityScreenState extends ConsumerState<EditCommunityScreen> {
  File? bannerImageFile;
  File? profileImageFile;

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

  void showCommunityBannerImageActionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            width: 40,
            color: Colors.grey,
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('View'),
            subtitle:
                const Text('Have a good look at your community\'s banner'),
            onTap: () => setState(
              () {
                // TODO: Do the view function
                Navigator.pop(context);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            subtitle: const Text('Change your community Banner Image'),
            onTap: () => setState(
              () {
                selectBannerImage();
                Navigator.pop(context);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            subtitle: const Text('Share with your friends'),
            onTap: () => setState(
              () {
                //Gonna do the share function
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void showCommunityProfileImageActionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 3,
            width: 40,
            color: Colors.grey,
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('View'),
            subtitle: const Text(
                'Have a good look at your community\'s profile image'),
            onTap: () => setState(
              () {
                //gonna do the view fucntion
                Navigator.pop(context);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            subtitle: const Text('Change your community Image Image'),
            onTap: () => setState(
              () {
                selectProfileImage();
                Navigator.pop(context);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            subtitle: const Text('Share with your friends'),
            onTap: () => setState(
              () {
                //Gonna do the share function
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void saveChanges(Community community) async {
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .editCommunityProfileOrBannerImage(
          community: community,
          profileImage: profileImageFile,
          bannerImage: bannerImageFile,
        );
    result.fold(
        (l) => showToast(false, l.toString()), (r) => showToast(true, r));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(communityControllerProvider);
    return ref.watch(getCommunityByIdProvider(widget.id)).when(
          data: (community) {
            if (community == null) {
              return const ErrorText(error: 'Unexpected Error Happenned');
            }
            return Scaffold(
              backgroundColor: Pallete.darkModeAppTheme.colorScheme.surface,
              appBar: AppBar(
                title: const Text('Edit Community'),
                centerTitle: false,
                actions: [
                  TextButton(
                    onPressed: () => saveChanges(community),
                    child: isLoading
                        ? const Loading()
                        : const Text(
                            'Save',
                            style: TextStyle(color: Pallete.whiteColor),
                          ),
                  ),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(8.0),
                child: !isLoading
                    ? Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: Stack(
                              children: [
                                InkWell(
                                  onTap: () {
                                    showCommunityBannerImageActionModal(
                                        context);
                                  },
                                  child: DottedBorder(
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
                                      child: bannerImageFile != null
                                          ? Image.file(bannerImageFile!)
                                          : community.bannerImage ==
                                                  Constants.bannerDefault
                                              ? const Center(
                                                  child: Icon(
                                                    Icons.camera_alt_outlined,
                                                    size: 40,
                                                  ),
                                                )
                                              : Image.network(
                                                  community.bannerImage,
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress ==
                                                        null) {
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
                                  child: GestureDetector(
                                    onTap: () =>
                                        showCommunityProfileImageActionModal(
                                            context),
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundImage: profileImageFile != null
                                          ? FileImage(profileImageFile!)
                                          : CachedNetworkImageProvider(
                                                  community.profileImage)
                                              as ImageProvider<Object>,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const Loading(),
              ),
            );
          },
          error: (error, stackTrace) => ErrorText(error: error.toString()),
          loading: () => const Loading(),
        );
  }
}

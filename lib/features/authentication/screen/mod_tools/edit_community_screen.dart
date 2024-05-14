import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/gaming_community/controller/gaming_comunity_controller.dart';
import 'package:hash_balance/theme/pallette.dart';

class EditCommunityScreen extends ConsumerStatefulWidget {
  final String name;
  const EditCommunityScreen({super.key, required this.name});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EditCommunityScreenState();
}

class _EditCommunityScreenState extends ConsumerState<EditCommunityScreen> {
  File? bannerFile;
  File? profileImage;

  void selectBannerImage() async {
    final result = await pickImage();
    if (result != null) {
      setState(() {
        bannerFile = File(result.files.first.path!);
      });
    }
  }

  void selectProfileImage() async {
    final result = await pickImage();
    if (result != null) {
      setState(() {
        profileImage = File(result.files.first.path!);
      });
    }
  }

  void showCommunityBannerActionModal(BuildContext context) {
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
          const SizedBox(height: 10),
          const Text(
            'Choose a new image',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(getCommunitiesByNameProvider(widget.name)).when(
          data: (community) => Scaffold(
            backgroundColor: Pallete.darkModeAppTheme.colorScheme.background,
            appBar: AppBar(
              title: const Text('Edit Community'),
              centerTitle: false,
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Pallete.whiteColor),
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            return showCommunityBannerActionModal(context);
                          },
                          child: DottedBorder(
                            borderType: BorderType.RRect,
                            radius: const Radius.circular(40),
                            dashPattern: const [10, 4],
                            strokeCap: StrokeCap.round,
                            color: Pallete
                                .darkModeAppTheme.textTheme.bodyMedium!.color!,
                            child: Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: bannerFile != null
                                  ? Image.file(bannerFile!)
                                  : community.bannerImage.isEmpty ||
                                          community.bannerImage ==
                                              Constants.bannerDefault
                                      ? const Center(
                                          child: Icon(
                                            Icons.camera_alt_outlined,
                                            size: 40,
                                          ),
                                        )
                                      : Image.network(community.bannerImage),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: GestureDetector(
                            onLongPress: () => selectProfileImage(),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(
                                community.profileImage,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          error: (error, stackTrace) => ErrorText(
            error: error.toString(),
          ),
          loading: () => const LoadingCircular(),
        );
  }
}

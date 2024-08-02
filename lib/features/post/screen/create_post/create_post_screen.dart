import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/theme/pallette.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  CreatePostScreenState createState() => CreatePostScreenState();
}

class CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final contentController = TextEditingController();
  File? image;
  File? video;
  Community? selectedCommunity;

  bool isSelectingImage = false;
  bool isSelectingVideo = false;
  VideoPlayerController? _videoPlayerController;

  bool isCreatingPost = false;

  @override
  void dispose() {
    contentController.dispose();
    if (_videoPlayerController != null) {
      _videoPlayerController!.dispose();
    }
    super.dispose();
  }

  void selectImage() async {
    final result = await pickImage();
    if (result != null) {
      setState(() {
        image = File(result.files.first.path!);
      });
    }
  }

  void selectVideo() async {
    final result = await pickVideo();
    if (result != null) {
      setState(() {
        isSelectingVideo = true;
        video = File(result.files.first.path!);
        _videoPlayerController = VideoPlayerController.file(video!)
          ..initialize().then((_) {
            setState(() {});
            _videoPlayerController!.play();
          });
      });
    }
  }

  void createPost(String uid) async {
    final result = await ref.read(postControllerProvider.notifier).createPost(
        uid, selectedCommunity!, image, video, contentController.text);
    result.fold((l) {
      setState(() {
        isCreatingPost = false;
      });
      return showToast(false, l.toString());
    }, (r) {
      setState(() {
        isCreatingPost = false;
      });
      return showToast(true, r);
    });
  }

  void navigateToCommunity() {
    final bottomNavState = context.findAncestorStateOfType<HomeScreenState>();
    if (bottomNavState != null) {
      bottomNavState.onTabTapped(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final isInAnyCommunities = ref.watch(userCommunitiesProvider);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Create Your Own Post'),
        ),
        body: isInAnyCommunities.when(
            data: (communities) {
              if (communities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_add,
                        color: Colors.white.withOpacity(0.6),
                        size: 80,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'You have to join at least ONE community to create a post!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          navigateToCommunity();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        child: const Text('Join a Community'),
                      ),
                    ],
                  ),
                );
              } else {
                return GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: Container(
                    color: Colors.black,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage:
                                    NetworkImage(user!.profileImage),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  const Row(
                                    children: [
                                      Icon(Icons.public,
                                          size: 16, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text(
                                        'Public',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  child: TextField(
                                    controller: contentController,
                                    keyboardType: TextInputType.text,
                                    autocorrect: false,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Hey ${user.name}, what are you thinking?',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    maxLines: null,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                isSelectingImage
                                    ? InkWell(
                                        onTap: () {
                                          selectImage();
                                        },
                                        onLongPress: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text('Confirm'),
                                                content: const Text(
                                                  'Do you want to cancel the image selection?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('No'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        isSelectingImage =
                                                            false;
                                                        image = null;
                                                      });
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('Yes'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Stack(
                                          children: [
                                            DottedBorder(
                                              borderType: BorderType.RRect,
                                              dashPattern: const [10, 4],
                                              strokeCap: StrokeCap.round,
                                              color: Pallete.darkModeAppTheme
                                                  .textTheme.bodyMedium!.color!,
                                              child: Container(
                                                width: double.infinity,
                                                height: 150,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: image != null
                                                    ? Image.file(image!)
                                                    : const Center(
                                                        child: Icon(
                                                            Icons
                                                                .camera_alt_outlined,
                                                            size: 40),
                                                      ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 10,
                                              right: 10,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5,
                                                        horizontal: 10),
                                                color: Colors.black
                                                    .withOpacity(0.5),
                                                child: const Text(
                                                  'Long press to cancel',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                                isSelectingVideo
                                    ? InkWell(
                                        onTap: () {
                                          selectVideo();
                                        },
                                        onLongPress: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text('Confirm'),
                                                content: const Text(
                                                    'Do you want to cancel the video selection?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('No'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        isSelectingVideo =
                                                            false;
                                                        video = null;
                                                      });
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('Yes'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        child: Stack(
                                          children: [
                                            DottedBorder(
                                              borderType: BorderType.RRect,
                                              dashPattern: const [10, 4],
                                              strokeCap: StrokeCap.round,
                                              color: Pallete.darkModeAppTheme
                                                  .textTheme.bodyMedium!.color!,
                                              child: Container(
                                                width: double.infinity,
                                                height: 150,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: video != null
                                                    ? Center(
                                                        child: AspectRatio(
                                                          aspectRatio:
                                                              _videoPlayerController!
                                                                  .value
                                                                  .aspectRatio,
                                                          child: VideoPlayer(
                                                            _videoPlayerController!,
                                                          ),
                                                        ),
                                                      )
                                                    : const Center(
                                                        child: Icon(
                                                          Icons
                                                              .videocam_outlined,
                                                          size: 40,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 10,
                                              right: 10,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 5,
                                                        horizontal: 10),
                                                color: Colors.black
                                                    .withOpacity(0.5),
                                                child: const Text(
                                                  'Long press to cancel',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                                if (!(contentController.text.trim() == '' &&
                                    image == null &&
                                    video == null))
                                  ref.watch(userCommunitiesProvider).when(
                                    data: (communities) {
                                      if (communities.isEmpty) {
                                        return const Text(
                                            'No communities available.');
                                      } else {
                                        if (selectedCommunity == null ||
                                            !communities.any((community) =>
                                                community ==
                                                selectedCommunity)) {
                                          selectedCommunity = null;
                                        }
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 15),
                                            DropdownButtonFormField<Community>(
                                              value: selectedCommunity,
                                              hint: const Text(
                                                  'Choose community'),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  selectedCommunity = newValue;
                                                });
                                              },
                                              items: communities.map<
                                                      DropdownMenuItem<
                                                          Community>>(
                                                  (Community community) {
                                                return DropdownMenuItem<
                                                    Community>(
                                                  value: community,
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 16,
                                                        backgroundImage:
                                                            CachedNetworkImageProvider(
                                                                community
                                                                    .profileImage),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                          '#=${community.name}'),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12),
                                                filled: true,
                                                fillColor: Colors.black,
                                                errorText: selectedCommunity ==
                                                        null
                                                    ? 'This field is required'
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                    error: (error, stackTrace) {
                                      return ErrorText(error: error.toString());
                                    },
                                    loading: () {
                                      return const Loading();
                                    },
                                  ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.image,
                                            color: Colors.white),
                                        onPressed: () {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            setState(() {
                                              isSelectingImage = true;
                                            });
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.video_library,
                                            color: Colors.white),
                                        onPressed: () {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            setState(() {
                                              isSelectingVideo = true;
                                            });
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.tag_faces,
                                            color: Colors.white),
                                        onPressed: () {},
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.location_on,
                                            color: Colors.white),
                                        onPressed: () {},
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.gif,
                                            color: Colors.white),
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: isCreatingPost
                                      ? const Loading()
                                      : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              isCreatingPost = true;
                                              createPost(user.uid);
                                            });
                                          },
                                          child: const Center(
                                              child: Text('Post',
                                                  style: TextStyle(
                                                      color: Colors.black))),
                                        ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            error: (Object error, StackTrace stackTrace) =>
                ErrorText(error: error.toString()),
            loading: () => const Loading()));
  }
}

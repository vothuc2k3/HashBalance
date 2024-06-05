import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:video_player/video_player.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  CreatePostScreenState createState() => CreatePostScreenState();
}

class CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final contentController = TextEditingController();
  String? communityName;
  File? image;
  File? video;

  bool isSelectingImage = false;
  bool isSelectingVideo = false;
  late VideoPlayerController _videoPlayerController;

  @override
  void dispose() {
    contentController.dispose();
    _videoPlayerController.dispose();
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
            _videoPlayerController.play();
          });
      });
    }
  }

  void createPost(String uid) async {
    final result = await ref.read(postControllerProvider.notifier).createPost(
          uid,
          communityName!,
          image,
          video,
          contentController.text,
        );
    result.fold((l) => showSnackBar(context, l.toString()),
        (r) => showMaterialBanner(context, r.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Create Your Own Post'),
      ),
      body: GestureDetector(
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
                      backgroundImage: NetworkImage(user!.profileImage),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: const TextStyle(color: Colors.white)),
                        const Row(
                          children: [
                            Icon(Icons.public, size: 16, color: Colors.white),
                            SizedBox(width: 5),
                            Text('Public',
                                style: TextStyle(color: Colors.white)),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                // Wrap with Expanded
                child: SingleChildScrollView(
                  // Wrap with SingleChildScrollView
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
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.5)),
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
                                          'Do you want to cancel the image selection?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
                                          },
                                          child: const Text('No'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              isSelectingImage = false;
                                              image = null;
                                            });
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
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
                                    color: Pallete.darkModeAppTheme.textTheme
                                        .bodyMedium!.color!,
                                    child: Container(
                                      width: double.infinity,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: image != null
                                          ? Image.file(image!)
                                          : const Center(
                                              child: Icon(
                                                  Icons.camera_alt_outlined,
                                                  size: 40),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 10),
                                      color: Colors.black.withOpacity(0.5),
                                      child: const Text(
                                        'Long press to cancel',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12),
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
                                                .pop(); // Close the dialog
                                          },
                                          child: const Text('No'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              isSelectingVideo = false;
                                              video = null;
                                            });
                                            Navigator.of(context)
                                                .pop(); // Close the dialog
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
                                    color: Pallete.darkModeAppTheme.textTheme
                                        .bodyMedium!.color!,
                                    child: Container(
                                      width: double.infinity,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: video != null
                                          ? Center(
                                              child: AspectRatio(
                                                aspectRatio:
                                                    _videoPlayerController
                                                        .value.aspectRatio,
                                                child: VideoPlayer(
                                                    _videoPlayerController),
                                              ),
                                            )
                                          : const Center(
                                              child: Icon(
                                                Icons.videocam_outlined,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5, horizontal: 10),
                                      color: Colors.black.withOpacity(0.5),
                                      child: const Text(
                                        'Long press to cancel',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Row(
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.image, color: Colors.white),
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
                              icon: const Icon(Icons.gif, color: Colors.white),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          onPressed: () {},
                          child: const Center(
                              child: Text('Post',
                                  style: TextStyle(color: Colors.black))),
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
      ),
    );
  }
}

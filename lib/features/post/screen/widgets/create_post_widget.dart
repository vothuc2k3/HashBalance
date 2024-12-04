import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/newsfeed/controller/newsfeed_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/community/controller/community_controller.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class CreatePostWidget extends ConsumerStatefulWidget {
  const CreatePostWidget({super.key});

  @override
  ConsumerState<CreatePostWidget> createState() => _CreatePostWidgetState();
}

class _CreatePostWidgetState extends ConsumerState<CreatePostWidget> {
  List<Community> communities = [];
  Community? selectedCommunity;
  bool isSelectingVideo = false;
  VideoPlayerController? _videoPlayerController;
  File? video;
  List<File> images = [];

  final contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    contentController.addListener(_onTextChanged);
  }

  Future<void> _selectImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      for (var pickedFile in pickedFiles) {
        setState(() {
          images.add(File(pickedFile.path));
        });
      }
    }
  }

  void _selectVideo() async {
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

  void _createPost() async {
    if (selectedCommunity == null) {
      showToast(false, 'Please select a community to post in.');
      return;
    } else if (contentController.text.isEmpty) {
      showToast(false, 'Please enter some content post.');
      return;
    } else {
      final result = await ref.read(postControllerProvider.notifier).createPost(
            community: selectedCommunity!,
            content: contentController.text,
            images: images,
            video: video,
          );
      result.fold(
        (l) {
          showToast(false, l.message);
        },
        (r) {
          showToast(true, 'Post created successfully');
          contentController.clear();
          setState(
            () {
              images.clear();
              video = null;
            },
          );
          ref.invalidate(newsfeedInitPostsProvider);
          context.findAncestorStateOfType<HomeScreenState>()?.onTabTapped(0);
        },
      );
    }
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.read(userProvider)!;
    final loading = ref.watch(postControllerProvider);

    return Container(
      decoration: BoxDecoration(
        color: ref.watch(preferredThemeProvider).first,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ref.watch(userCommunitiesProvider).when(
              data: (data) {
                if (data.isEmpty) {
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
                            _navigateToCommunityListScreen();
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
                  ).animate().fadeIn();
                }
                communities = data;
                return SingleChildScrollView(
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => _showSelectCommunityDialog(data),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            color: const Color(0xff181C30),
                            child: selectedCommunity == null
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Select Community',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                          selectedCommunity!.profileImage,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        selectedCommunity!.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        _buildUserWidget(user: currentUser),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              TextField(
                                controller: contentController,
                                keyboardType: TextInputType.text,
                                autocorrect: false,
                                decoration: InputDecoration(
                                  hintText:
                                      'Hey ${currentUser.name}, what are you thinking?',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  border: InputBorder.none,
                                ),
                                maxLines: null,
                                maxLength: 3000,
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _selectImages,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                                child: const Text(
                                  'Pick Images',
                                  style: TextStyle(
                                    color: Colors.white60,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              images.isNotEmpty
                                  ? InkWell(
                                      onTap: () => _selectImages(),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: StaggeredGrid.count(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 4.0,
                                          crossAxisSpacing: 4.0,
                                          children: images.map((image) {
                                            return Stack(
                                              alignment: Alignment.topRight,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: AspectRatio(
                                                    aspectRatio: 1,
                                                    child: Image.file(
                                                      image,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close,
                                                      color: Colors.red),
                                                  onPressed: () {
                                                    setState(() {
                                                      images.remove(image);
                                                    });
                                                  },
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _selectVideo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                                child: const Text(
                                  'Pick Video',
                                  style: TextStyle(
                                    color: Colors.white60,
                                  ),
                                ),
                              ),
                              isSelectingVideo
                                  ? InkWell(
                                      onTap: () {
                                        _selectVideo();
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
                                                            _videoPlayerController!),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5,
                                                      horizontal: 10),
                                              color:
                                                  Colors.black.withOpacity(0.5),
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
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                  ),
                                  onPressed: _createPost,
                                  child: loading
                                      ? const Loading()
                                      : const Text(
                                          'Post',
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(),
                  ),
                );
              },
              error: (Object error, StackTrace stackTrace) =>
                  ErrorText(error: error.toString()),
              loading: () => const Loading(),
            ),
      ),
    );
  }

  void _navigateToCommunityListScreen() {
    final bottomNavState = context.findAncestorStateOfType<HomeScreenState>();
    if (bottomNavState != null) {
      bottomNavState.onTabTapped(1);
    }
  }

  void _showSelectCommunityDialog(List<Community> communities) async {
    final chosenCommunity = await showDialog<Community>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text('Select Community'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: communities.map(
                (community) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(
                        community.profileImage,
                      ),
                    ),
                    title: Text(community.name),
                    onTap: () {
                      Navigator.of(context).pop(community);
                    },
                  );
                },
              ).toList(),
            ),
          ),
        );
      },
    );

    if (chosenCommunity != null) {
      setState(() {
        selectedCommunity = chosenCommunity;
      });
    }
  }

  Widget _buildUserWidget({required UserModel user}) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(
              user.profileImage,
            ),
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
                  Icon(Icons.public, size: 16, color: Colors.white),
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
      ).animate().fadeIn(),
    );
  }
}

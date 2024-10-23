import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:video_player/video_player.dart';

import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/theme/pallette.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final Community? _chosenCommunity;
  final bool? _isFromCommunityScreen;

  const CreatePostScreen({
    super.key,
    Community? chosenCommunity,
    bool? isFromCommunityScreen,
  })  : _chosenCommunity = chosenCommunity,
        _isFromCommunityScreen = isFromCommunityScreen;

  @override
  CreatePostScreenState createState() => CreatePostScreenState();
}

class CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with AutomaticKeepAliveClientMixin {
  List<Community> communities = [];
  final contentController = TextEditingController();
  final pollQuestionController = TextEditingController();
  final List<TextEditingController> pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  File? image;
  File? video;
  Community? selectedCommunity;
  bool isCreatingPoll = false;

  bool isSelectingImage = false;
  bool isSelectingVideo = false;
  VideoPlayerController? _videoPlayerController;

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

  void _selectImage() async {
    final result = await pickImage();
    if (result != null) {
      setState(() {
        image = File(result.files.first.path!);
      });
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
          community: selectedCommunity!, content: contentController.text);
      result.fold(
        (l) {
          showToast(false, l.toString());
        },
        (r) {
          contentController.clear();
          switch (widget._isFromCommunityScreen) {
            case true:
              Navigator.of(context).pop();
              break;
            default:
              final homeScreenState =
                  context.findAncestorStateOfType<HomeScreenState>();
              homeScreenState?.onTabTapped(0);
              super.dispose();
              break;
          }
        },
      );
    }
  }

  void _createPoll() async {
    if (selectedCommunity == null) {
      showToast(false, 'Please select a community to create a poll in.');
      return;
    } else if (pollQuestionController.text.isEmpty ||
        pollOptionControllers.any((controller) => controller.text.isEmpty)) {
      showToast(false, 'Please complete the poll question and all options.');
      return;
    } else {
      final result = await ref.read(postControllerProvider.notifier).createPoll(
          communityId: selectedCommunity!.id,
          question: pollQuestionController.text,
          options: pollOptionControllers
              .map((controller) => controller.text.trim())
              .toList());
      result.fold(
        (l) {
          showToast(false, l.message);
        },
        (r) {
          showToast(true, 'Poll created successfully!');
          pollQuestionController.clear();
          for (var controller in pollOptionControllers) {
            controller.clear();
          }
        },
      );
    }
  }

  void _navigateToCommunityListScreen() {
    final bottomNavState = context.findAncestorStateOfType<HomeScreenState>();
    if (bottomNavState != null) {
      bottomNavState.onTabTapped(1);
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: ref.watch(preferredThemeProvider).second,
      title: const Text('Posting'),
    );
  }

  Widget _buildPollWidget({
    required List<Community> communities,
    required UserModel currentUser,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ref.watch(preferredThemeProvider).first,
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showSelectCommunityDialog(communities),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: selectedCommunity == null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
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
                            const Spacer(),
                            Switch(
                              value: isCreatingPoll,
                              onChanged: (value) {
                                setState(() {
                                  isCreatingPoll = value;
                                });
                              },
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Spacer(),
                            CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  selectedCommunity!.profileImage),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              selectedCommunity!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: isCreatingPoll,
                              onChanged: (value) {
                                setState(() {
                                  isCreatingPoll = value;
                                });
                              },
                            ),
                          ],
                        ),
                ),
              ),
              _buildUserWidget(user: currentUser),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: pollQuestionController,
                      decoration: const InputDecoration(
                        hintText: 'Enter poll question...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    ...pollOptionControllers.map((controller) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'Poll option',
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: const OutlineInputBorder(),
                            suffixIcon: pollOptionControllers.length > 2
                                ? IconButton(
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        pollOptionControllers
                                            .remove(controller);
                                      });
                                    },
                                  )
                                : null,
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                    if (pollOptionControllers.length < 10)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              ref.watch(preferredThemeProvider).third,
                        ),
                        onPressed: () {
                          setState(() {
                            pollOptionControllers.add(TextEditingController());
                          });
                        },
                        child: const Text(
                          'Add Option',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _createPoll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            ref.watch(preferredThemeProvider).third,
                      ),
                      child: const Text(
                        'Create Poll',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(),
        ),
      ),
    );
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

  @override
  void initState() {
    super.initState();
    selectedCommunity = widget._chosenCommunity;
  }

  @override
  void dispose() {
    contentController.dispose();
    pollQuestionController.dispose();
    for (var controller in pollOptionControllers) {
      controller.dispose();
    }
    if (_videoPlayerController != null) {
      _videoPlayerController!.dispose();
    }
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    bool isCreatingPost = ref.watch(postControllerProvider);
    final currentUser = ref.watch(userProvider);

    return Scaffold(
      appBar: widget._isFromCommunityScreen == true ? _buildAppBar() : null,
      body: isCreatingPoll
          ? _buildPollWidget(
              communities: communities, currentUser: currentUser!)
          : Container(
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
                        return GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: widget._isFromCommunityScreen != null &&
                                        widget._isFromCommunityScreen == true
                                    ? () {}
                                    : () => _showSelectCommunityDialog(data),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  color: const Color(0xff181C30),
                                  child: selectedCommunity == null
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Spacer(),
                                            Icon(
                                              Icons.add_circle_outline,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Select Community',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Spacer(),
                                            Switch(
                                              value: isCreatingPoll,
                                              onChanged: (value) {
                                                setState(() {
                                                  isCreatingPoll = value;
                                                });
                                              },
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            const Spacer(),
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
                                            const Spacer(),
                                            Switch(
                                              value: isCreatingPoll,
                                              onChanged: (value) {
                                                setState(() {
                                                  isCreatingPoll = value;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              _buildUserWidget(user: currentUser!),
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
                                                'Hey ${currentUser.name}, what are you thinking?',
                                            hintStyle: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.5),
                                            ),
                                            border: InputBorder.none,
                                          ),
                                          maxLines: null,
                                          maxLength: 3000,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                      isSelectingImage
                                          ? InkWell(
                                              onTap: () {
                                                _selectImage();
                                              },
                                              onLongPress: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title:
                                                          const Text('Confirm'),
                                                      content: const Text(
                                                        'Do you want to cancel the image selection?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child:
                                                              const Text('No'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              isSelectingImage =
                                                                  false;
                                                              image = null;
                                                            });
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child:
                                                              const Text('Yes'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              child: Stack(
                                                children: [
                                                  DottedBorder(
                                                    borderType:
                                                        BorderType.RRect,
                                                    dashPattern: const [10, 4],
                                                    strokeCap: StrokeCap.round,
                                                    color: Pallete
                                                        .darkModeAppTheme
                                                        .textTheme
                                                        .bodyMedium!
                                                        .color!,
                                                    child: Container(
                                                      width: double.infinity,
                                                      height: 150,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
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
                                                      padding: const EdgeInsets
                                                          .symmetric(
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
                                                _selectVideo();
                                              },
                                              onLongPress: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title:
                                                          const Text('Confirm'),
                                                      content: const Text(
                                                          'Do you want to cancel the video selection?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child:
                                                              const Text('No'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              isSelectingVideo =
                                                                  false;
                                                              video = null;
                                                            });
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child:
                                                              const Text('Yes'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              child: Stack(
                                                children: [
                                                  DottedBorder(
                                                    borderType:
                                                        BorderType.RRect,
                                                    dashPattern: const [10, 4],
                                                    strokeCap: StrokeCap.round,
                                                    color: Pallete
                                                        .darkModeAppTheme
                                                        .textTheme
                                                        .bodyMedium!
                                                        .color!,
                                                    child: Container(
                                                      width: double.infinity,
                                                      height: 150,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: video != null
                                                          ? Center(
                                                              child:
                                                                  AspectRatio(
                                                                aspectRatio:
                                                                    _videoPlayerController!
                                                                        .value
                                                                        .aspectRatio,
                                                                child:
                                                                    VideoPlayer(
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
                                                      padding: const EdgeInsets
                                                          .symmetric(
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
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 1),
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
                                              icon: const Icon(
                                                  Icons.video_library,
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
                                              icon: const Icon(
                                                  Icons.location_on,
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
                                                  backgroundColor: ref
                                                      .watch(
                                                          preferredThemeProvider)
                                                      .third,
                                                ),
                                                onPressed: _createPost,
                                                child: const Center(
                                                  child: Text(
                                                    'Post',
                                                    style: TextStyle(
                                                        color: Colors.black),
                                                  ),
                                                ),
                                              ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(),
                        );
                      },
                      error: (Object error, StackTrace stackTrace) =>
                          ErrorText(error: error.toString()),
                      loading: () => const Loading(),
                    ),
              ),
            ),
    );
  }
}

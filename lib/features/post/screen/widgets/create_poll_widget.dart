import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';

class CreatePollWidget extends ConsumerStatefulWidget {
  const CreatePollWidget({
    super.key,
  });

  @override
  ConsumerState<CreatePollWidget> createState() => _CreatePollWidgetState();
}

class _CreatePollWidgetState extends ConsumerState<CreatePollWidget> {
  bool isCreatingPoll = false;
  Community? selectedCommunity;

  final pollQuestionController = TextEditingController();
  final List<TextEditingController> pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.read(userProvider)!;

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
              ref.watch(userCommunitiesProvider).whenOrNull(
                    data: (communities) {
                      return GestureDetector(
                        onTap: () => _showSelectCommunityDialog(communities),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          child: selectedCommunity == null
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                  ],
                                ),
                        ),
                      );
                    },
                  ) ??
                  const SizedBox.shrink(),
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
      ),
    );
  }
}

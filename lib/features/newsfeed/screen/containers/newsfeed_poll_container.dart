// ignore_for_file: use_build_context_synchronously

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/post/screen/edit_post_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/poll_option_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PollContainer extends ConsumerStatefulWidget {
  final UserModel author;
  final Post poll;
  final Community community;

  const PollContainer({
    super.key,
    required this.author,
    required this.poll,
    required this.community,
  });

  @override
  ConsumerState<PollContainer> createState() => _PollContainerState();
}

class _PollContainerState extends ConsumerState<PollContainer> {
  bool isLoading = false;
  UserModel? currentUser;

  @override
  void didChangeDependencies() {
    currentUser = ref.read(userProvider)!;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final pollId = widget.poll.id;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(10),
      color: ref.watch(preferredThemeProvider).second,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPollHeader(),
          const SizedBox(height: 8),
          Text(
            widget.poll.content,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ref.watch(getUserPollOptionVoteProvider(pollId)).when(
                data: (votedOptionId) {
                  return Column(
                      children: ref.watch(getPollOptionsProvider(pollId)).when(
                            data: (options) => options.map((option) {
                              final isSelected = votedOptionId == option.id;
                              return InkWell(
                                onTap: () =>
                                    _handleOptionTap(optionId: option.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.green
                                        : ref
                                            .watch(preferredThemeProvider)
                                            .third,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 12),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          option.option,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            error: (error, stackTrace) {
                              return [
                                Text('Error: $error',
                                    style: const TextStyle(color: Colors.red))
                              ];
                            },
                            loading: () => [const Loading()],
                          ));
                },
                loading: () => const Loading(),
                error: (error, stackTrace) => Text('Error: $error',
                    style: const TextStyle(color: Colors.red)),
              ),
        ],
      ),
    );
  }

  Widget _buildPollHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage:
              CachedNetworkImageProvider(widget.community.profileImage),
          radius: 20,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.community.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              formatTime(widget.poll.createdAt),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showMoreOption(),
        ),
      ],
    );
  }

  void _deletePoll() async {
    await ref
        .read(postControllerProvider.notifier)
        .deletePoll(pollId: widget.poll.id);
  }

  void _handleDeletePoll() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this poll?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  color: Colors.white,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child:
                  const Text('No', style: TextStyle(color: Colors.greenAccent)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePoll();
              },
              child:
                  const Text('Yes', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _showMoreOption() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: ref.watch(preferredThemeProvider).first,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.poll.uid == currentUser!.uid)
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit Poll'),
                    onTap: () {
                      Navigator.pop(context);
                      _handleEditPoll();
                    },
                  ),
                if (currentUser!.uid == widget.author.uid)
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Delete Poll'),
                    onTap: () {
                      Navigator.pop(context);
                      _handleDeletePoll();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Close'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        });
  }

  void _handleOptionTap({
    required String optionId,
  }) async {
    await ref
        .read(postControllerProvider.notifier)
        .voteOption(pollId: widget.poll.id, optionId: optionId);
  }

  void _handleEditPoll() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
    List<PollOption> pollOptions = [];
    pollOptions = await ref
        .read(postControllerProvider.notifier)
        .getPollOptions(pollId: widget.poll.id)
        .first;
    if (widget.poll.uid == currentUser!.uid) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EditPostScreen(
            post: widget.poll,
            initialPollOptions: pollOptions,
          ),
        ),
      );
    }
  }
}

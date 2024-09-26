import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/poll_model.dart';
import 'package:hash_balance/models/poll_option_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PollContainer extends ConsumerStatefulWidget {
  final UserModel author;
  final Poll poll;
  final List<PollOption> options;
  final Community community;

  const PollContainer({
    super.key,
    required this.author,
    required this.poll,
    required this.options,
    required this.community,
  });

  @override
  ConsumerState<PollContainer> createState() => _PollContainerState();
}

class _PollContainerState extends ConsumerState<PollContainer> {
  bool isLoading = false;
  UserModel? currentUser;

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
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Poll'),
                  onTap: () {
                    Navigator.pop(context);
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
                  leading: const Icon(Icons.cancel),
                  title: const Text('Cancel Poll'),
                  onTap: () {
                    Navigator.pop(context);
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

  @override
  void didChangeDependencies() {
    currentUser = ref.read(userProvider)!;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
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
            widget.poll.question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ref.watch(getUserPollOptionVoteProvider(widget.poll.id)).when(
                data: (votedOptionId) {
                  return Column(
                    children: widget.options.map((option) {
                      final isSelected = votedOptionId == option.id;
                      return InkWell(
                        onTap: isLoading
                            ? null
                            : () => _handleOptionTap(optionId: option.id),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.green
                                : ref.watch(preferredThemeProvider).third,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option.option,
                                  style: const TextStyle(color: Colors.white),
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
                  );
                },
                loading: () => const CircularProgressIndicator(),
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
          backgroundImage: NetworkImage(widget.community.profileImage),
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
}

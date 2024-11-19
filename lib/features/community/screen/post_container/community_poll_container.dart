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
import 'package:hash_balance/models/poll_option_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:tuple/tuple.dart';

class PollContainer extends ConsumerStatefulWidget {
  final UserModel author;
  final Post poll;
  final String communityId;

  const PollContainer({
    super.key,
    required this.author,
    required this.poll,
    required this.communityId,
  });

  @override
  ConsumerState<PollContainer> createState() => _PollContainerState();
}

class _PollContainerState extends ConsumerState<PollContainer> {
  bool isLoading = false;
  UserModel? currentUser;
  List<PollOption>? previousOptions;
  String? previousVotedOptionId;

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
    final pollId = widget.poll.id;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ref.watch(preferredThemeProvider).second,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
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
          ref.watch(getUserPollOptionVoteProvider(pollId)).whenOrNull(
                    data: (votedOptionId) {
                      previousVotedOptionId = votedOptionId;
                      return _buildPollOptions(pollId, votedOptionId);
                    },
                    loading: () {
                      if (previousVotedOptionId != null) {
                        return _buildPollOptions(pollId, previousVotedOptionId);
                      } else {
                        return const Loading();
                      }
                    },
                    error: (error, stackTrace) => Text('Error: $error',
                        style: const TextStyle(color: Colors.red)),
                  ) ??
              const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildPollOptions(String pollId, String? votedOptionId) {
    final asyncValue = ref.watch(getPollOptionsProvider(pollId));

    return asyncValue.when(
      data: (options) {
        previousOptions = options;

        return Column(
          children: options.map((option) {
            final isSelected = votedOptionId == option.id;
            final optionVoteCountState = ref.watch(
              getPollOptionVotesCountAndUserVoteStatusProvider(
                Tuple2(pollId, option.id),
              ),
            );

            return optionVoteCountState.when(
              data: (voteData) {
                final voteCount = voteData.item2;
                return InkWell(
                  onTap: () => _handleOptionTap(optionId: option.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green
                          : ref.watch(preferredThemeProvider).third,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.option,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        Text(
                          '$voteCount votes',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => _buildLoadingOption(option, isSelected),
              error: (error, stackTrace) => Text(
                'Error: $error',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }).toList(),
        );
      },
      error: (error, stackTrace) =>
          Text('Error: $error', style: const TextStyle(color: Colors.red)),
      loading: () => previousOptions != null
          ? _buildLoadingOptionsUI(previousOptions!, votedOptionId)
          : const Loading(),
    );
  }

  Widget _buildLoadingOption(PollOption option, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color:
            isSelected ? Colors.green : ref.watch(preferredThemeProvider).third,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              option.option,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16, height: 16, child: Loading()),
        ],
      ),
    );
  }

  Widget _buildLoadingOptionsUI(
      List<PollOption> options, String? votedOptionId) {
    return Column(
      children: options.map((option) {
        final isSelected = votedOptionId == option.id;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.green
                : ref.watch(preferredThemeProvider).third,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option.option,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPollHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage:
              CachedNetworkImageProvider(widget.author.profileImage),
          radius: 20,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.author.name,
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

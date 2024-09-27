import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:tuple/tuple.dart';

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
  Widget? oldWidget;

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
              children: widget.options.map((option) {
                // Lấy AsyncValue từ provider
                final asyncValue = ref.watch(
                  getPollOptionVotesCountAndUserVoteStatusProvider(
                    Tuple2(widget.poll.id, option.id),
                  ),
                );

                // Sử dụng copyWithPrevious để giữ giá trị trước đó
                final mergedAsyncValue =
                    asyncValue.copyWithPrevious(asyncValue);

                // Sử dụng maybeWhen để chỉ cập nhật khi có dữ liệu mới, nếu không giữ trạng thái cũ
                return mergedAsyncValue.maybeWhen(
                  data: (data) {
                    final votedOptionId = data.item1;
                    final voteCount = data.item2;

                    final isSelected = votedOptionId == option.id;

                    return InkWell(
                      onTap: isLoading
                          ? null
                          : () => _handleOptionTap(optionId: option.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
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
                                '${option.option} ($voteCount votes)', // Hiển thị số lượng vote đúng cho từng option
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
                  },
                  orElse: () =>
                      oldWidget ??
                      Container(), // Giữ trạng thái cũ nếu không có dữ liệu mới
                );
              }).toList(),
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
          Column(
            children: widget.options.map((option) {
              // Lấy AsyncValue từ provider
              final asyncValue = ref.watch(
                getPollOptionVotesCountAndUserVoteStatusProvider(
                  Tuple2(widget.poll.id, option.id),
                ),
              );

              final mergedAsyncValue = asyncValue.copyWithPrevious(asyncValue);

              return mergedAsyncValue.whenData((data) {
                    final votedOptionId = data.item1;
                    final voteCount = data.item2;

                    final isSelected = votedOptionId == option.id;

                    oldWidget = InkWell(
                      onTap: isLoading
                          ? null
                          : () => _handleOptionTap(optionId: option.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
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
                                '${option.option} ($voteCount votes)',
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
                    return oldWidget!;
                  }).valueOrNull ??
                  oldWidget!;
            }).toList(),
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
}

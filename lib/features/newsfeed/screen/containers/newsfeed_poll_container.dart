import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/models/poll_model.dart';
import 'package:hash_balance/models/user_model.dart';

class PollContainer extends ConsumerStatefulWidget {
  final UserModel author;
  final Poll poll;

  const PollContainer({
    super.key,
    required this.author,
    required this.poll,
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(10),
      color: Colors.white.withOpacity(0.05),
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
          ..._buildOptions(),
          const SizedBox(height: 8),
          _buildPollStat(),
        ],
      ),
    );
  }

  Widget _buildPollHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(widget.author.profileImage),
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
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }

  List<Widget> _buildOptions() {
    return List<Widget>.generate(widget.poll.options.length, (index) {
      final option = widget.poll.options[index];
      return InkWell(
        onTap: isLoading ? null : () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option['option'],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const Icon(
                Icons.check,
                color: Colors.green,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPollStat() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () {},
          child: const Row(
            children: [
              Icon(Icons.comment, size: 18, color: Colors.white70),
              SizedBox(width: 4),
              Text(
                '0 Comments',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        isLoading ? const Loading() : const SizedBox.shrink(),
      ],
    );
  }
}

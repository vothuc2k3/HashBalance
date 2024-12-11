import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/post/screen/widgets/edit_poll_widget.dart';
import 'package:hash_balance/features/post/screen/widgets/edit_post_widget.dart';
import 'package:hash_balance/models/poll_option_model.dart';
import 'package:hash_balance/models/post_model.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  final Post _post;
  final List<PollOption>? initialPollOptions;

  const EditPostScreen({
    required Post post,
    this.initialPollOptions,
    super.key,
  }) : _post = post;

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  late List<PollOption> pollOptions;
  
  @override
  void initState() {
    super.initState();
    pollOptions = widget.initialPollOptions ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return widget._post.isPoll
        ? EditPollWidget(
            post: widget._post,
            pollOptions: pollOptions,
          )
        : EditPostWidget(
            post: widget._post,
          );
  }
}

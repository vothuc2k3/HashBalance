import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/post/screen/widgets/edit_poll_widget.dart';
import 'package:hash_balance/features/post/screen/widgets/edit_post_widget.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
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
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    pollOptions = widget.initialPollOptions ?? [];
  }

  void _savePost() async {
    // Save post logic
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: ref.watch(preferredThemeProvider).first,
        appBar: AppBar(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: Text(widget._post.isPoll ? 'Edit Poll' : 'Edit Post'),
          actions: [
            IconButton(
              onPressed: isSaving ? null : _savePost,
              icon: const Icon(Icons.save),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: widget._post.isPoll
                ? EditPollWidget(post: widget._post, pollOptions: pollOptions)
                : EditPostWidget(post: widget._post),
          ),
        ),
      ),
    );
  }
}

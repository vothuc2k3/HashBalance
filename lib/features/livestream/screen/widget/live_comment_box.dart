import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/livestream/controller/livestream_controller.dart';

class LiveCommentBox extends ConsumerStatefulWidget {
  final String streamId;

  const LiveCommentBox({super.key, required this.streamId});

  @override
  ConsumerState<LiveCommentBox> createState() => LiveCommentBoxState();
}

class LiveCommentBoxState extends ConsumerState<LiveCommentBox> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _sendComment() {
    final content = _commentController.text.trim();
    if (content.isNotEmpty) {
      ref.read(livestreamControllerProvider).createLivestreamComment(
            uid: ref.read(userProvider)!.uid,
            streamId: widget.streamId,
            content: content,
          );
      _commentController.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ref.watch(getLivestreamCommentsProvider(widget.streamId)).when(
                data: (comments) {
                  if (comments.isEmpty) {
                    return const Center(child: Text('No comments yet.'));
                  }

                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: comments.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child:
                              Text(comment.uid.substring(0, 1).toUpperCase()),
                        ),
                        title: Text(comment.uid),
                        subtitle: Text(comment.content),
                      );
                    },
                  );
                },
                error: (error, stack) => Center(child: Text(error.toString())),
                loading: () => const Center(child: Loading()),
              ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your comment...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendComment,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

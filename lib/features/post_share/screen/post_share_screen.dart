import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/plain_post_container.dart';
import 'package:hash_balance/features/post_share/controller/post_share_controller.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:mdi/mdi.dart';

class PostShareScreen extends ConsumerStatefulWidget {
  final Post post;
  final UserModel author;
  final Community community;

  const PostShareScreen({
    super.key,
    required this.post,
    required this.author,
    required this.community,
  });

  @override
  ConsumerState<PostShareScreen> createState() => _PostShareScreenState();
}

class _PostShareScreenState extends ConsumerState<PostShareScreen> {
  final TextEditingController shareTextController = TextEditingController();

  @override
  void dispose() {
    shareTextController.dispose();
    super.dispose();
  }

  void _sharePost() {
    final content = shareTextController.text.trim();
    ref
        .read(postShareControllerProvider.notifier)
        .sharePost(postId: widget.post.id, content: content)
        .then((result) {
      result.fold(
        (error) => showToast(false, error.message),
        (_) {
          showToast(true, 'Shared successfully!');
          Navigator.pop(context);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ref.watch(preferredThemeProvider).first,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: shareTextController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Add a message to your share...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: _sharePost,
                      icon: const Icon(Mdi.sendCheck),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PlainPostContainer(
                  post: widget.post,
                  author: widget.author,
                  community: widget.community,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

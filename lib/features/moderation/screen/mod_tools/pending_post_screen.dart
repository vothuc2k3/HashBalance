import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/post_data_model.dart';
import 'package:hash_balance/features/moderation/screen/post_container/pending_post_container.dart';
import 'package:hash_balance/models/post_model.dart';

class PendingPostScreen extends ConsumerStatefulWidget {
  final Community _community;

  const PendingPostScreen({
    super.key,
    required Community community,
  }) : _community = community;

  @override
  PendingPostScreenState createState() => PendingPostScreenState();
}

class PendingPostScreenState extends ConsumerState<PendingPostScreen> {
  late Future<List<PostDataModel>> pendingPosts;

  void _handlePostApproval(Post post, String decision) async {
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .handlePostApproval(post, decision);
    result.fold(
      (l) => showToast(false, l.message),
      (r) {
        showToast(true, 'Approved post!');
        setState(() {
          pendingPosts = ref
              .read(postControllerProvider.notifier)
              .getPendingPosts(widget._community);
        });
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    pendingPosts = ref
        .read(postControllerProvider.notifier)
        .getPendingPosts(widget._community);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Posts'),
      ),
      body: FutureBuilder<List<PostDataModel>>(
        future: pendingPosts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Loading();
          } else if (snapshot.hasError) {
            return ErrorText(error: snapshot.error.toString());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('There\'s no pending posts...'),
            );
          } else {
            final posts = snapshot.data!;
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PendingPostContainer(
                  author: post.author,
                  post: post.post,
                  handlePostApproval: _handlePostApproval,
                );
              },
            );
          }
        },
      ),
    );
  }
}

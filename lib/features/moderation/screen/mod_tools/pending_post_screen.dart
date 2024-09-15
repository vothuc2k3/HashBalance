import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/theme/controller/theme_controller.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
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
        _onRefresh(); // Refresh the list after approval
      },
    );
  }

  Future<void> _onRefresh() async {
    setState(() {
      pendingPosts = ref
          .read(postControllerProvider.notifier)
          .getPendingPosts(widget._community);
    });
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
        backgroundColor: ref.watch(preferredThemeProvider),
      ),
      body: Container(
        color: ref.watch(preferredThemeProvider),
        child: FutureBuilder<List<PostDataModel>>(
          future: pendingPosts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Loading();
            } else if (snapshot.hasError) {
              return ErrorText(error: snapshot.error.toString());
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: const Text(
                  'There\'s no any pending posts.....',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ).animate().fadeIn(duration: 600.ms).moveY(
                      begin: 30,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),
              );
            } else {
              final posts = snapshot.data!;
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return PendingPostContainer(
                      author: post.author!,
                      post: post.post,
                      handlePostApproval: _handlePostApproval,
                    );
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

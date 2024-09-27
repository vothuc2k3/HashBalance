import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/features/moderation/screen/post_container/pending_post_container.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  void _handlePostApproval(Post post, String decision) async {
    final result = await ref
        .read(moderationControllerProvider.notifier)
        .handlePostApproval(post, decision);
    result.fold(
      (l) => showToast(false, l.message),
      (r) {
        showToast(true, 'Approved post!');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Posts'),
        backgroundColor: ref.watch(preferredThemeProvider).second,
      ),
      body: Container(
        color: ref.watch(preferredThemeProvider).first,
        child: ref.watch(getPendingPostsProvider(widget._community.id)).when(
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: const Text(
                      'No pending posts awaiting...',
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
                }
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return PendingPostContainer(
                      post: data[index].post,
                      author: data[index].author!,
                      handlePostApproval: _handlePostApproval,
                    );
                  },
                );
              },
              error: (error, stack) => ErrorText(error: error.toString()),
              loading: () => const Center(child: Loading()),
            ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/widgets/rejected_post_container.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';

class RejectedPostScreen extends ConsumerStatefulWidget {
  const RejectedPostScreen({super.key, required this.community});

  final Community community;

  @override
  RejectedPostScreenState createState() => RejectedPostScreenState();
}

class RejectedPostScreenState extends ConsumerState<RejectedPostScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejected Posts'),
        backgroundColor: ref.watch(preferredThemeProvider).second,
      ),
      body: Container(
        color: ref.watch(preferredThemeProvider).first,
        child: ref.watch(getRejectedPostsProvider(widget.community.id)).when(
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: const Text(
                      'No rejected posts awaiting...',
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
                    return RejectedPostContainer(
                      post: data[index].post,
                      author: data[index].author!,
                      community: widget.community,
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

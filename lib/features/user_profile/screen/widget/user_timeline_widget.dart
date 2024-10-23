import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/newsfeed/screen/containers/newsfeed_post_container.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';

class UserTimelineWidget extends ConsumerStatefulWidget {
  const UserTimelineWidget({
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UserTimelineWidgetState();
}

class _UserTimelineWidgetState extends ConsumerState<UserTimelineWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider)!;
    super.build(context);
    return Container(
      decoration: BoxDecoration(
        color: ref.watch(preferredThemeProvider).first,
      ),
      child: RefreshIndicator(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ref.watch(userPostsProvider(currentUser)).when(
                    data: (posts) {
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final postData = posts[index];
                          return PostContainer(
                            author: currentUser,
                            post: postData.post,
                            community: postData.community!,
                          ).animate().fadeIn();
                        },
                      );
                    },
                    error: (e, s) => ErrorText(error: e.toString()),
                    loading: () => const Loading(),
                  ),
            )
          ],
        ),
        onRefresh: () async {},
      ),
    );
  }
}

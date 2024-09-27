import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/newsfeed/screen/containers/newsfeed_post_container.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/user_model.dart';

class UserTimelineWidget extends ConsumerStatefulWidget {
  const UserTimelineWidget({
    required UserModel user,
    super.key,
  }) : _user = user;

  final UserModel _user;

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
    super.build(context);
    return Container(
      decoration: BoxDecoration(
        color: ref.watch(preferredThemeProvider).first,
      ),
      child: RefreshIndicator(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ref.watch(userPostsProvider(widget._user)).when(
                    data: (posts) {
                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final postData = posts[index];
                          return PostContainer(
                            author: widget._user,
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

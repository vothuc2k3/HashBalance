import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/widgets/post_share_container.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/newsfeed/screen/containers/newsfeed_poll_container.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/features/user_profile/screen/widget/timeline_post_container.dart';
import 'package:hash_balance/models/user_model.dart';

class UserTimelineWidget extends ConsumerStatefulWidget {
  const UserTimelineWidget({
    super.key,
    required this.user,
  });

  final UserModel user;

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
        color: ref.watch(preferredThemeProvider).third,
      ),
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ref.watch(userTimelineProvider(widget.user)).when(
                    data: (timelineItems) {
                      if (timelineItems.isEmpty) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Text(
                              currentUser.uid == widget.user.uid
                                  ? 'You have no posts yet...'
                                  : 'This guy has no posts yet...',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ).animate().fadeIn(duration: 600.ms).moveY(
                                  begin: 30,
                                  end: 0,
                                  duration: 600.ms,
                                  curve: Curves.easeOutBack,
                                ),
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: timelineItems.length,
                        itemBuilder: (context, index) {
                          final timelineItem = timelineItems[index];

                          if (timelineItem.isShare) {
                            return PostShareContainer(
                              postShareData: timelineItem.postShareData!,
                            ).animate().fadeIn();
                          } else if (timelineItem.postData!.post.isPoll) {
                            return NewsfeedPollContainer(
                              author: widget.user,
                              poll: timelineItem.postData!.post,
                              community: timelineItem.postData!.community!,
                            ).animate().fadeIn();
                          } else {
                            return TimelinePostContainer(
                              author: widget.user,
                              post: timelineItem.postData!.post,
                              community: timelineItem.postData!.community!,
                            ).animate().fadeIn();
                          }
                        },
                      );
                    },
                    error: (e, s) => ErrorText(error: e.toString()),
                    loading: () => SizedBox(
                      height: MediaQuery.of(context).size.height,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Loading(),
                            Text(
                              'Loading posts...',
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    ref.invalidate(userTimelineProvider);
  }
}

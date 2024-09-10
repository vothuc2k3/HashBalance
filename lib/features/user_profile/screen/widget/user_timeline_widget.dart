import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/newsfeed/screen/post_container/post_container.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UserTimelineWidget extends ConsumerStatefulWidget {
  const UserTimelineWidget({
    super.key,
    required Future<List<PostDataModel>> userPostsFuture,
    
  }) : _userPostsFuture = userPostsFuture;

  final Future<List<PostDataModel>> _userPostsFuture;

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
    final currentUser = ref.watch(userProvider)!;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF000000),
            Color(0xFF0D47A1),
            Color(0xFF1976D2),
          ],
        ),
      ),
      child: RefreshIndicator(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: FutureBuilder(
                future: widget._userPostsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Loading',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Loading(),
                      ].animate().fadeIn(duration: 600.ms).moveY(
                            begin: 30,
                            end: 0,
                            duration: 600.ms,
                            curve: Curves.easeOutBack,
                          ),
                    );
                  } else if (snapshot.hasError) {
                    return ErrorText(error: snapshot.error.toString());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: SizedBox.shrink(),
                    );
                  } else if (snapshot.connectionState == ConnectionState.done) {
                    final posts = snapshot.data!;
                    return ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final postData = posts[index];
                        return PostContainer(
                          author: currentUser,
                          post: postData.post,
                          community: postData.community,
                        ).animate().fadeIn();
                      },
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            )
          ],
        ),
        onRefresh: () async {},
      ),
    );
  }
}

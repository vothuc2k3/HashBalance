import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';
import 'package:hash_balance/core/widgets/community_card.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';

import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:tuple/tuple.dart';

class CommunityListScreen extends ConsumerStatefulWidget {
  const CommunityListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CommunityListScreenState();
}

class _CommunityListScreenState extends ConsumerState<CommunityListScreen>
    with AutomaticKeepAliveClientMixin {
  UserModel? currentUser;
  List<Tuple2<Community, int>> _communities = <Tuple2<Community, int>>[];

  void _navigateToCommunityScreen(
    Community community,
    String uid,
  ) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
    final result = await ref
        .read(communityControllerProvider.notifier)
        .fetchSuspendStatus(communityId: community.id, uid: uid);
    result.fold(
      (l) {
        showToast(false, 'Unexpected error happened...');
      },
      (r) {
        if (r) {
          showToast(false, 'You are suspended from this community');
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityScreen(
                communityId: community.id,
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _onRefresh() async {
    ref.invalidate(getTopCommunityListProvider);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    currentUser = ref.read(userProvider)!;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: RefreshIndicator.adaptive(
        onRefresh: _onRefresh,
        child: Container(
          color: ref.watch(preferredThemeProvider).first,
          child: ref.watch(getTopCommunityListProvider).when(
                data: (communities) {
                  _communities = communities;
                  if (_communities.isEmpty) {
                    return Center(
                      child: const Text(
                        'There\'s no any communities :(',
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
                    return ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _communities.length,
                      itemBuilder: (context, index) {
                        final community = _communities[index];
                        return CommunityCard(
                          community: community.item1,
                          memberCount: community.item2,
                          onTap: () => _navigateToCommunityScreen(
                              community.item1, currentUser!.uid),
                          themeProvider:
                              ref.watch(preferredThemeProvider).third,
                        ).animate().fadeIn();
                      },
                    );
                  }
                },
                error: (error, stack) => ErrorText(error: error.toString()),
                loading: () => const Loading(),
              ),
        ),
      ),
    );
  }
}

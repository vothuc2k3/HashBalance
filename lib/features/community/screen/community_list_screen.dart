import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hash_balance/features/theme/controller/theme_controller.dart';

import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';

class CommunityListScreen extends ConsumerStatefulWidget {
  const CommunityListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CommunityListScreenState();
}

class _CommunityListScreenState extends ConsumerState<CommunityListScreen>
    with AutomaticKeepAliveClientMixin {
  UserModel? currentUser;
  late Stream<List<Community>?> communitiesStream;

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
        .read(moderationControllerProvider.notifier)
        .fetchMembershipStatus(getMembershipId(uid, community.id));

    result.fold(
      (l) {
        showToast(false, 'Unexpected error happened...');
      },
      (r) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityScreen(
              communityId: community.id,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    setState(() {
      communitiesStream = ref
          .read(communityControllerProvider.notifier)
          .getTopCommunitiesList();
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    currentUser = ref.read(userProvider)!;
    communitiesStream =
        ref.watch(communityControllerProvider.notifier).getTopCommunitiesList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: RefreshIndicator.adaptive(
        onRefresh: _onRefresh,
        child: Container(
          color: ref.watch(preferredThemeProvider),
          child: StreamBuilder<List<Community>?>(
            stream: communitiesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Loading());
              } else if (snapshot.hasError) {
                return ErrorText(error: snapshot.error.toString());
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                final communities = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: communities.length,
                  itemBuilder: (context, index) {
                    final community = communities[index];
                    return Card(
                      color: Colors.black,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                            community.profileImage,
                          ),
                          radius: 30,
                        ),
                        title: Text(
                          community.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          community.description,
                          style: const TextStyle(color: Colors.white70),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people, color: Colors.white70),
                            SizedBox(height: 4),
                            Text(
                              '82964',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        onTap: () => _navigateToCommunityScreen(
                            community, currentUser!.uid),
                      ),
                    ).animate().fadeIn();
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

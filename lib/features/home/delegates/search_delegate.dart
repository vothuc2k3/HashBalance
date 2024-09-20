import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';

import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/search/controller/search_controller.dart';
import 'package:hash_balance/features/theme/controller/theme_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';

class SearchCommunityDelegate extends SearchDelegate {
  final WidgetRef ref;
  SearchCommunityDelegate(this.ref);

  // Ghi đè hàm buildAppBar để tạo AppBar tùy chỉnh
  @override
  ThemeData appBarTheme(BuildContext context) {
    // Lấy màu từ preferredThemeProvider
    Color appBarColor = ref.watch(preferredThemeProvider);

    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor, // Đặt màu AppBar
        iconTheme: const IconThemeData(
          color: Colors.white, // Màu của biểu tượng trong AppBar
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white, // Màu của tiêu đề
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(
          color: Colors.white, // Màu của hint text trong ô tìm kiếm
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return <Widget>[
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return const SizedBox();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final currentUser = ref.watch(userProvider)!;
    Color color = ref.watch(preferredThemeProvider);

    Widget buildListItem({
      required String title,
      required String imageUrl,
      required VoidCallback onTap,
    }) {
      return Card(
        color: color,
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(imageUrl),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          onTap: onTap,
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: color),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (query.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        query = '#';
                        showSuggestions(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.person_4, color: Colors.white),
                            SizedBox(width: 10),
                            Text('#', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        query = '#=';
                        showSuggestions(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.people, color: Colors.white),
                            SizedBox(width: 10),
                            Text('#=', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        query = '=';
                        showSuggestions(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.article, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              '=',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              else
                Expanded(
                  child: ref.watch(searchProvider(query)).when(
                        data: (data) {
                          if (query.startsWith('#=')) {
                            return ListView.separated(
                              itemCount: data.length,
                              itemBuilder: (BuildContext context, int index) {
                                final community = data[index];
                                return buildListItem(
                                  title: community.name,
                                  imageUrl: community.profileImage,
                                  onTap: () {
                                    _navigateToCommunityScreen(
                                      context,
                                      community,
                                      currentUser.uid,
                                    );
                                  },
                                );
                              },
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const Divider(color: Colors.grey),
                            );
                          } else if (query.startsWith('#')) {
                            return ListView.separated(
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final user = data[index];
                                if (user.uid == currentUser.uid) {
                                  return const SizedBox.shrink();
                                }
                                return buildListItem(
                                  title: '#${user.name}',
                                  imageUrl: user.profileImage,
                                  onTap: () {
                                    navigateToProfileScreen(context, user);
                                  },
                                );
                              },
                              separatorBuilder:
                                  (BuildContext context, int index) {
                                final user = data[index];
                                if (user.uid == currentUser.uid) {
                                  return const SizedBox.shrink();
                                }
                                return const Divider(color: Colors.grey);
                              },
                            );
                          } else {
                            return const SizedBox();
                          }
                        },
                        error: (error, stackTrace) =>
                            ErrorText(error: error.toString()),
                        loading: () => const Loading(),
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCommunityScreen(
    BuildContext context,
    Community community,
    String uid,
  ) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
    String? membershipStatus;
    final result = await ref
        .watch(moderationControllerProvider.notifier)
        .fetchMembershipStatus(getMembershipId(uid, community.id));

    result.fold(
      (l) {
        showToast(false, 'Unexpected error happened...');
      },
      (r) {
        membershipStatus = r;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityScreen(
              memberStatus: membershipStatus!,
              communityId: community.id,
            ),
          ),
        );
      },
    );
  }

  void navigateToProfileScreen(BuildContext context, UserModel targetUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(
          targetUid: targetUser.uid,
        ),
      ),
    );
  }
}

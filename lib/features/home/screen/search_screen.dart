import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:hash_balance/core/widgets/community_card.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/widgets/search_bar.dart' as search_bar;
import 'package:hash_balance/core/widgets/user_card.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/community/screen/community_screen.dart';
import 'package:hash_balance/features/newsfeed/screen/containers/newsfeed_poll_container.dart';
import 'package:hash_balance/features/newsfeed/screen/containers/newsfeed_post_container.dart';
import 'package:hash_balance/features/search/controller/search_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/user_model.dart';

class SearchSuggestionsScreen extends ConsumerStatefulWidget {
  const SearchSuggestionsScreen({super.key});

  @override
  ConsumerState<SearchSuggestionsScreen> createState() =>
      _SearchSuggestionsScreenState();
}

class _SearchSuggestionsScreenState
    extends ConsumerState<SearchSuggestionsScreen> {
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _query = query;
        Logger().d(_query);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        elevation: 1,
        title: search_bar.SearchBar(
          onQueryChanged: _onQueryChanged,
          color: ref.watch(preferredThemeProvider).first,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: _query.isNotEmpty
              ? (_query.startsWith('#=') // Tìm kiếm cộng đồng
                  ? ref.watch(searchCommunityProvider(_query)).when(
                        data: (suggestions) {
                          if (suggestions.isEmpty) {
                            return Center(
                              child: Text(
                                'No communities found for "$_query"',
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
                            );
                          }
                          return ListView.builder(
                            itemCount: suggestions.length,
                            itemBuilder: (context, index) {
                              final community = suggestions[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: CommunityCard(
                                  community: community,
                                  themeProvider:
                                      ref.watch(preferredThemeProvider).third,
                                  onTap: () => _onCommunityTap(community),
                                  memberCount: ref
                                      .watch(getCommunityMemberCountProvider(
                                          community.id))
                                      .when(
                                        data: (data) => data,
                                        error: (error, stack) => 0,
                                        loading: () => 0,
                                      ),
                                ).animate().fadeIn(duration: 400.ms).moveY(
                                      begin: 20,
                                      end: 0,
                                      duration: 400.ms,
                                      curve: Curves.easeOut,
                                    ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: Loading(),
                        ).animate().fadeIn(duration: 600.ms).moveY(
                              begin: 30,
                              end: 0,
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            ),
                        error: (error, stack) => Center(
                          child: Text(
                            'Error: $error',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ).animate().fadeIn(duration: 600.ms).moveY(
                              begin: 30,
                              end: 0,
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            ),
                      )
                  : (_query.startsWith('#') // Tìm kiếm người dùng
                      ? ref.watch(searchUserProvider(_query)).when(
                            data: (suggestions) {
                              final currentUser = ref.watch(userProvider)!;
                              if (suggestions.contains(currentUser)) {
                                suggestions.remove(currentUser);
                              }
                              if (suggestions.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No users found for "$_query"',
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
                                );
                              }
                              return ListView.builder(
                                itemCount: suggestions.length,
                                itemBuilder: (context, index) {
                                  final user = suggestions[index];
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: UserCard(
                                      user: user,
                                      isAdmin: true,
                                      theme: ref
                                          .watch(preferredThemeProvider)
                                          .third,
                                      onTap: () => _onUserTap(user),
                                    ).animate().fadeIn(duration: 400.ms).moveY(
                                          begin: 20,
                                          end: 0,
                                          duration: 400.ms,
                                          curve: Curves.easeOut,
                                        ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                              child: Loading(),
                            ).animate().fadeIn(duration: 600.ms).moveY(
                                  begin: 30,
                                  end: 0,
                                  duration: 600.ms,
                                  curve: Curves.easeOutBack,
                                ),
                            error: (error, stack) => Center(
                              child: Text(
                                'Error: $error',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ).animate().fadeIn(duration: 600.ms).moveY(
                                  begin: 30,
                                  end: 0,
                                  duration: 600.ms,
                                  curve: Curves.easeOutBack,
                                ),
                          )
                      : (_query.startsWith('=')
                          ? ref.watch(searchPostsProvider(_query)).when(
                                data: (posts) {
                                  if (posts.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No posts found for "$_query"',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white70,
                                        ),
                                      )
                                          .animate()
                                          .fadeIn(duration: 600.ms)
                                          .moveY(
                                            begin: 30,
                                            end: 0,
                                            duration: 600.ms,
                                            curve: Curves.easeOutBack,
                                          ),
                                    );
                                  }
                                  return ListView.builder(
                                    itemCount: posts.length,
                                    itemBuilder: (context, index) {
                                      final postData = posts[index];
                                      if (!postData.post.isPoll) {
                                        return NewsfeedPostContainer(
                                          author: postData.author!,
                                          post: postData.post,
                                          community: postData.community!,
                                        ).animate().fadeIn();
                                      } else if (postData.post.isPoll) {
                                        return NewsfeedPollContainer(
                                          author: postData.author!,
                                          poll: postData.post,
                                          community: postData.community!,
                                        ).animate().fadeIn();
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  );
                                },
                                loading: () => const Center(
                                  child: Loading(),
                                ).animate().fadeIn(duration: 600.ms).moveY(
                                      begin: 30,
                                      end: 0,
                                      duration: 600.ms,
                                      curve: Curves.easeOutBack,
                                    ),
                                error: (error, stack) => Center(
                                  child: Text(
                                    'Error: $error',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ).animate().fadeIn(duration: 600.ms).moveY(
                                      begin: 30,
                                      end: 0,
                                      duration: 600.ms,
                                      curve: Curves.easeOutBack,
                                    ),
                              )
                          : const Center(
                              child: Text(
                                'Invalid search query. Please start with "#" or "#=".',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ).animate().fadeIn(duration: 600.ms).moveY(
                                begin: 30,
                                end: 0,
                                duration: 600.ms,
                                curve: Curves.easeOutBack,
                              ))))
              : Center(
                  child: const Text(
                    'Search for communities, users, or posts',
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
                ),
        ),
      ),
    );
  }

  _onCommunityTap(Community community) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityScreen(communityId: community.id),
      ),
    );
  }

  _onUserTap(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(
          targetUid: user.uid,
        ),
      ),
    );
  }
}

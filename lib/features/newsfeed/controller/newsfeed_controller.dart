import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/community_controller.dart';

import 'package:hash_balance/features/newsfeed/repository/newsfeed_repository.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';

final newsfeedInitPostsProvider = FutureProvider(
  (ref) =>
      ref.watch(newsfeedControllerProvider.notifier).getNewsfeedInitPosts(),
);

final newsfeedControllerProvider =
    StateNotifierProvider<NewsfeedController, bool>(
  (ref) {
    final newsfeedRepository = ref.read(newsfeedRepositoryProvider);
    return NewsfeedController(
      newsfeedRepository: newsfeedRepository,
      userController: ref.read(userControllerProvider.notifier),
      communityController: ref.read(communityControllerProvider.notifier),
      ref: ref,
    );
  },
);

class NewsfeedController extends StateNotifier<bool> {
  final NewsfeedRepository _newsfeedRepository;
  final UserController _userController;
  final CommunityController _communityController;
  final Ref _ref;

  NewsfeedController({
    required NewsfeedRepository newsfeedRepository,
    required UserController userController,
    required CommunityController communityController,
    required Ref ref,
  })  : _newsfeedRepository = newsfeedRepository,
        _userController = userController,
        _communityController = communityController,
        _ref = ref,
        super(false);

  Future<List<PostDataModel>> getNewsfeedInitPosts() async {
    final user = _ref.watch(userProvider)!;
    final userJoinedCommunitiesIds =
        await _userController.getUserJoinedCommunitiesIds(user.uid);
    if (userJoinedCommunitiesIds.isEmpty) {
      final topCommunityIdsList =
          await _communityController.getTopCommunitiesList();
      final topCommunityIds =
          topCommunityIdsList.map((e) => e.item1.id).toList();
      return await _newsfeedRepository.getNewsfeedInitPosts(
        communityIds: topCommunityIds,
      );
    } else {
      return await _newsfeedRepository.getNewsfeedInitPosts(
        communityIds: userJoinedCommunitiesIds,
      );
    }
  }

  Future<List<PostDataModel>> fetchMorePosts(
    Timestamp lastPostCreatedAt,
  ) async {
    final user = _ref.read(userProvider)!;
    final communityIds =
        await _userController.getUserJoinedCommunitiesIds(user.uid);
    return await _newsfeedRepository.fetchMorePosts(
      communityIds: communityIds,
      lastPostCreatedAt: lastPostCreatedAt,
    );
  }
}

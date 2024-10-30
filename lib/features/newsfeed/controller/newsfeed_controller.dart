import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';

import 'package:hash_balance/features/newsfeed/repository/newsfeed_repository.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final newsfeedInitPostsProvider = StreamProvider(
  (ref) =>
      ref.watch(newsfeedControllerProvider.notifier).getNewsfeedInitPosts(),
);

final newsfeedControllerProvider =
    StateNotifierProvider<NewsfeedController, bool>(
  (ref) {
    final newsfeedRepository = ref.read(newsfeedRepositoryProvider);
    return NewsfeedController(
      newsfeedRepository: newsfeedRepository,
      ref: ref,
    );
  },
);

class NewsfeedController extends StateNotifier<bool> {
  final NewsfeedRepository _newsfeedRepository;
  final Ref _ref;

  NewsfeedController({
    required NewsfeedRepository newsfeedRepository,
    required Ref ref,
  })  : _newsfeedRepository = newsfeedRepository,
        _ref = ref,
        super(false);

  Stream<List<PostDataModel>> getNewsfeedInitPosts() async* {
    final user = _ref.read(userProvider)!;
    final sharedPreferences = await SharedPreferences.getInstance();
    final communityIds = sharedPreferences
        .getStringList('userJoinedCommunities_${user.uid}')
        ?.cast<String>();
    if (communityIds != null && communityIds.isNotEmpty) {
      yield* _newsfeedRepository.getNewsfeedInitPosts(
          communityIds: communityIds);
    } else {
      yield* _newsfeedRepository.getNewsfeedRandomPosts();
    }
  }
}

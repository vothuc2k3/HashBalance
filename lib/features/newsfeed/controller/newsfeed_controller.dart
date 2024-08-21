import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/newsfeed/repository/newsfeed_repository.dart';
import 'package:hash_balance/models/post_model.dart';

final getCommunitiesPostsProvider = StreamProvider.autoDispose((ref) {
  return ref
      .watch(newsfeedControllerProvider.notifier)
      .getJoinedCommunitiesPosts();
});

final newsfeedControllerProvider =
    StateNotifierProvider<NewsfeedController, bool>(
  (ref) {
    final storageRepository = ref.watch(storageRepositoryProvider);
    final newsfeedRepository = ref.watch(newsfeedRepositoryProvider);
    return NewsfeedController(
      newsfeedRepository: newsfeedRepository,
      storageRepository: storageRepository,
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
    required StorageRepository storageRepository,
  })  : _newsfeedRepository = newsfeedRepository,
        _ref = ref,
        super(false);

  Stream<List<Post>> getJoinedCommunitiesPosts() {
    final user = _ref.watch(userProvider);
    return _newsfeedRepository.getJoinedCommunitiesPosts(user!.uid);
  }
}

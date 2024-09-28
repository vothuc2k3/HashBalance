import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/features/newsfeed/repository/newsfeed_repository.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';

final newsfeedStreamProvider = StreamProvider.family((ref, String uid) {
  return ref
      .watch(newsfeedControllerProvider.notifier)
      .getNewsfeedPosts(uid: uid);
});

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
  // ignore: unused_field
  final Ref _ref;

  NewsfeedController({
    required NewsfeedRepository newsfeedRepository,
    required Ref ref,
  })  : _newsfeedRepository = newsfeedRepository,
        _ref = ref,
        super(false);

  Stream<List<PostDataModel>> getNewsfeedPosts({
    required String uid,
  }) {
    return _newsfeedRepository.getNewsfeedPosts(uid: uid);
  }

}

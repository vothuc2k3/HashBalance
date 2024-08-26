import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/newsfeed/repository/newsfeed_repository.dart';
import 'package:hash_balance/models/post_data_model.dart';

final newsfeedControllerProvider = Provider(
  (ref) {
    final newsfeedRepository = ref.watch(newsfeedRepositoryProvider);
    return NewsfeedController(
      newsfeedRepository: newsfeedRepository,
      ref: ref,
    );
  },
);

class NewsfeedController {
  final NewsfeedRepository _newsfeedRepository;
  final Ref _ref;

  NewsfeedController({
    required NewsfeedRepository newsfeedRepository,
    required Ref ref,
  })  : _newsfeedRepository = newsfeedRepository,
        _ref = ref;

  Future<List<PostDataModel>> getJoinedCommunitiesPosts() async {
    final user = _ref.read(userProvider)!;
    final list = await _newsfeedRepository.getJoinedCommunitiesPosts(user.uid);
    for (var data in list) {
      print(data.toString());
    }
    return list;
  }
}

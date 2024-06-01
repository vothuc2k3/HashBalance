import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/newsfeed/repository/newsfeed_repository.dart';

final newsfeedController = StateNotifierProvider<NewsfeedController, bool>(
    (ref) => NewsfeedController(
        newsfeedRepository: ref.read(newsfeedRepositoryProvider), ref: ref));

class NewsfeedController extends StateNotifier<bool> {
  final NewsfeedRepository _newsfeedRepository;

  NewsfeedController({
    required NewsfeedRepository newsfeedRepository,
    required Ref ref,
  })  : _newsfeedRepository = newsfeedRepository,
        super(false);
}

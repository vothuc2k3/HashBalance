import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/post_share/post_share_repository/post_share_repository.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/post_share_model.dart';

final getFriendsSharePostsProvider = StreamProvider.family(
    (ref, List<String> friendUids) => ref
        .watch(postShareControllerProvider.notifier)
        .getFriendsSharePosts(friendUids));

final getPostShareCountProvider = StreamProvider.family((ref, String postId) =>
    ref.watch(postShareControllerProvider.notifier).getPostShareCount(postId));

final postShareControllerProvider = StateNotifierProvider((ref) {
  return PostShareController(
      postShareRepository: ref.watch(postShareRepositoryProvider), ref: ref);
});

class PostShareController extends StateNotifier<bool> {
  final PostShareRepository _postShareRepository;
  final Ref _ref;

  PostShareController({
    required PostShareRepository postShareRepository,
    required Ref ref,
  })  : _postShareRepository = postShareRepository,
        _ref = ref,
        super(false);

  //SHARE A POST
  Future<Either<Failures, void>> sharePost({
    required String postId,
    required String? content,
  }) async {
    try {
      final currentUid = _ref.watch(userProvider)!.uid;
      final postShare = PostShare(
        id: await generateRandomId(),
        postId: postId,
        uid: currentUid,
        content: content ?? '',
        createdAt: Timestamp.now(),
      );
      return await _postShareRepository.sharePost(postShare);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //FETCH THE NUMBER OF SHARE COUNT OF A POST
  Stream<int> getPostShareCount(String postId) {
    return _postShareRepository.getPostShareCount(postId);
  }

  // FETCH FRIENDS' SHARE POSTS
  Stream<List<Post>?> getFriendsSharePosts(List<String> friendUids) {
    return _postShareRepository.getFriendsSharePosts(friendUids);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/reply_comment/repository/reply_comment_repository.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:uuid/uuid.dart';

final getCommentRepliesProvider =
    StreamProvider.family.autoDispose((ref, String parentCommentId) {
  return ref
      .watch(replyCommentControllerProvider.notifier)
      .getCommentReplies(parentCommentId);
});

final replyCommentControllerProvider =
    StateNotifierProvider<ReplyCommentController, bool>(
  (ref) => ReplyCommentController(
    replyCommentRepository: ref.watch(replyCommentRepositoryProvider),
    ref: ref,
  ),
);

class ReplyCommentController extends StateNotifier<bool> {
  final ReplyCommentRepository _replyRepository;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  ReplyCommentController({
    required ReplyCommentRepository replyCommentRepository,
    required Ref ref,
  })  : _replyRepository = replyCommentRepository,
        _ref = ref,
        super(false);

  //COMMENT
  Future<Either<Failures, void>> reply(
    Post post,
    String parentCommentId,
    String? content,
  ) async {
    try {
      final user = _ref.watch(userProvider)!;
      final comment = CommentModel(
        uid: user.uid,
        postId: post.id,
        createdAt: Timestamp.now(),
        content: content,
        id: _uuid.v1(),
        parentCommentId: parentCommentId,
      );
      final result = await _replyRepository.reply(comment);
      return result.fold(
        (l) => left((Failures(l.message))),
        (r) => right(null),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //FETCH ALL COMMENT'S REPLIES
  Stream<List<CommentModel>?> getCommentReplies(String parentCommentId) {
    return _replyRepository.getCommentReplies(parentCommentId);
  }
}

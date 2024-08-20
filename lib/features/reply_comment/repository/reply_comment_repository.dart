import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/comment_model.dart';

final replyCommentRepositoryProvider = Provider((ref) {
  return ReplyCommentRepository(
      firestore: ref.watch(firebaseFirestoreProvider));
});

class ReplyCommentRepository {
  final FirebaseFirestore _firestore;

  ReplyCommentRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //REFERENCE ALL THE COMMENTS
  CollectionReference get _comments =>
      _firestore.collection(FirebaseConstants.commentsCollection);

//COMMENT ON A POST
  FutureVoid reply(CommentModel comment) async {
    try {
      await _comments.doc(comment.id).set(comment.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //FETCH ALL COMMENT'S REPLIES
  Stream<List<CommentModel>?> getCommentReplies(String parentCommentId) {
    return _comments
        .where('parentCommentId', isEqualTo: parentCommentId)
        .snapshots()
        .map((event) {
      if (event.docs.isEmpty) {
        return null;
      }
      List<CommentModel> replies = [];
      for (final doc in event.docs) {
        final data = doc.data() as Map<String, dynamic>;
        replies.add(CommentModel.fromMap(data));
      }
      final repliess = replies;
      return repliess;
    });
  }
}

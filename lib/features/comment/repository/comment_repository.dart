import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/comment_model.dart';

final commentRepositoryProvider = Provider((ref) {
  return CommentRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class CommentRepository {
  final FirebaseFirestore _firestore;

  CommentRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //REFERENCE ALL THE COMMENTS
  CollectionReference get _comments =>
      _firestore.collection(FirebaseConstants.commentsCollection);

//COMMENT ON A POST
  FutureVoid comment(CommentModel comment) async {
    try {
      await _comments.doc(comment.id).set(comment.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //FETCH ALL COMMENTS OF A POST
  Stream<List<CommentModel>?> getPostComments(String postId) {
    return _comments
        .where('postId', isEqualTo: postId)
        .where('parentCommentId', isEqualTo: '')
        .snapshots()
        .map(
      (event) {
        if (event.docs.isEmpty) {
          return null;
        } else {
          List<CommentModel> comments = <CommentModel>[];
          for (var doc in event.docs) {
            final data = doc.data() as Map<String, dynamic>;
            comments.add(CommentModel.fromMap(data));
          }
          return comments;
        }
      },
    );
  }
}

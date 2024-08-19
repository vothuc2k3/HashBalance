import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/post_share_model.dart';

final postShareRepositoryProvider = Provider((ref) {
  return PostShareRepository(firestore: ref.watch(firebaseFirestoreProvider));
});

class PostShareRepository {
  final FirebaseFirestore _firestore;

  PostShareRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //REFERENCE ALL THE USERS
  CollectionReference get _postShares =>
      _firestore.collection(FirebaseConstants.postShareCollection);

  //SHARE A POST
  FutureVoid sharePost(PostShare postShare) async {
    try {
      await _postShares.doc(postShare.id).set(postShare.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //FETCH THE NUMBER OF SHARE COUNT OF A POST
  Stream<int> getPostShareCount(String postId) {
    return _postShares
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((event) {
      return event.size;
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/gaming_community.dart';

class GamingCommunityRepository {
  FirebaseFirestore _firestore;

  GamingCommunityRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  FutureVoid createGamingCommunity(GamingCommunityModel community) async {
    try {
      var communityDoc = await _communities.doc(community.name).get();
      if (communityDoc.exists) {
        throw 'The name is already exists!';
      }
      return right(
        _communities.doc(community.name).set(
              community.toMap(),
            ),
      );
    } on FirebaseException catch (e) {
      return left(
        Failures(e.message!),
      );
    } catch (e) {
      return left(
        Failures(
          e.toString(),
        ),
      );
    }
  }

  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
}

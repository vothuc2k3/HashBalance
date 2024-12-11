import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/badge_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final badgeRepositoryProvider = Provider((ref) => BadgeRepository(
      firestore: ref.read(firebaseFirestoreProvider),
    ));

class BadgeRepository {
  final FirebaseFirestore _firestore;

  BadgeRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //REFERENCE ALL THE BADGES
  CollectionReference get _badges =>
      _firestore.collection(FirebaseConstants.badgesCollection);

  Stream<List<BadgeModel>> getBadges() {
    return _badges.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => BadgeModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<Either<Failures, void>> createBadge(BadgeModel badge) async {
    try {
      await _badges.add(badge.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message ?? "An unknown error occurred"));
    } on Exception catch (e) {
      return left(Failures(e.toString()));
    }
  }
}

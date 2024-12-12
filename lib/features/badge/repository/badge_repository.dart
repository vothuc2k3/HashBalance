import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/badge_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

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
  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

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

  Stream<bool> hasBadge({
    required String uid,
    required String badgeId,
  }) {
    return _users.doc(uid).snapshots().map((event) {
      final doc = event.data() as Map<String, dynamic>;
      final badges = List<String>.from(doc['badgeIds'] ?? []);
      Logger().d('Badges: $badges');
      return badges.contains(badgeId);
    });
  }
}

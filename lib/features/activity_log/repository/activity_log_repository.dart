import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/activity_log_model.dart';

final activityLogRepositoryProvider = Provider((ref) {
  return ActivityLogRepository(
    firestore: ref.read(firebaseFirestoreProvider),
  );
});

class ActivityLogRepository {
  final FirebaseFirestore _firestore;

  ActivityLogRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  CollectionReference get _activityLogs =>
      _firestore.collection(FirebaseConstants.activityLogsCollection);

  Future<Either<Failures, void>> clearActivityLogs() async {
    try {
      final batch = _firestore.batch();
      await _activityLogs.get().then((value) {
        for (var doc in value.docs) {
          batch.delete(doc.reference);
        }
      });
      await batch.commit();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> addActivityLog(
      ActivityLogModel activityLog) async {
    try {
      await _activityLogs.doc(activityLog.id).set(activityLog.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<List<ActivityLogModel>> getActivityLog({required String uid}) {
    return _activityLogs
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                ActivityLogModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }
}

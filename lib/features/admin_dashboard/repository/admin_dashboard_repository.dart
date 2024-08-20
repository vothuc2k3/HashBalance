import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';

final adminDashboardRepositoryProvider = Provider((ref) =>
    AdminDashboardRepository(firestore: ref.watch(firebaseFirestoreProvider)));

class AdminDashboardRepository {
  final FirebaseFirestore _firestore;

  AdminDashboardRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  Stream<Map<int, int>> getTodayPostsCountByHour(String communityId) {
    final todayStart =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    return _post
        .where('createdAt', isGreaterThanOrEqualTo: todayStart)
        .where('createdAt', isLessThan: tomorrowStart)
        .snapshots()
        .map((snapshot) {
      final counts = <int, int>{};
      for (var doc in snapshot.docs) {
        final timestamp = (doc['createdAt'] as Timestamp).toDate();
        final hour = timestamp.hour;
        counts[hour] = (counts[hour] ?? 0) + 1;
      }
      return counts;
    });
  }

  //REFERENCE ALL THE POSTs
  CollectionReference get _post =>
      _firestore.collection(FirebaseConstants.postsCollection);
}

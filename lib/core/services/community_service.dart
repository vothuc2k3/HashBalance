import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> getUserJoinedCommunities(String uid) async {
    List<String> communityIds = [];
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection(FirebaseConstants.communityMembershipCollection)
          .where('uid', isEqualTo: uid)
          .get();
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        communityIds.add(data['communityId'] as String);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('userJoinedCommunities_$uid', communityIds);
    } catch (e) {
      throw Exception(e);
    }
  }
}

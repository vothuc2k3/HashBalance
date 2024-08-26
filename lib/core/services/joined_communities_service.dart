import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/hive_models/community/hive_community_model.dart';
import 'package:hive/hive.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/models/user_model.dart';

class JoinedCommunitiesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // REFERENCE TO THE USERS COLLECTION
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  // REFERENCE TO THE COMMUNITIES COLLECTION
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);

  void fetchJoinedCommunities(
    UserModel? userData,
  ) async {
    List<HiveCommunityModel> joinedCommunities = [];

    if (userData != null) {
      final joinedCommunitiesBox =
          await Hive.openBox<HiveCommunityModel>('joined_communities_box');

      final uid = userData.uid;

      final userSnapshot = await _users.doc(uid).get();
      if (userSnapshot.exists) {
        final data = userSnapshot.data() as Map<String, dynamic>;
        final joinedCommunityIds =
            List<String>.from(data['joinedCommunities'] ?? []);

        for (final communityId in joinedCommunityIds) {
          final communitySnapshot = await _communities.doc(communityId).get();
          if (communitySnapshot.exists) {
            final communityData =
                communitySnapshot.data() as Map<String, dynamic>;
            final hiveCommunityModel =
                HiveCommunityModel.fromMap(communityData);
            joinedCommunities.add(hiveCommunityModel);

            // Save to Hive
            joinedCommunitiesBox.put(communityId, hiveCommunityModel);
          }
        }
        for (final community in joinedCommunitiesBox.values) {
          Constants.communityIds.add(community.id);
        }
      }
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hive/hive.dart';

import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/hive_models/hive_user_model.dart';

class UserFriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // REFERENCE TO THE FRIENDSHIP COLLECTION
  CollectionReference get _friendship =>
      _firestore.collection(FirebaseConstants.friendshipCollection);

  // REFERENCE TO THE USERS COLLECTION
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  UserFriendsService();

  Future<List<HiveUserModel>> fetchUserFriends(UserModel? userData) async {
    List<String> friendsUids = [];

    if (userData != null) {
      final uid = userData.uid;

      // Fetch friends where user is uid1
      final friendsSnapshot =
          await _friendship.where('uid1', isEqualTo: uid).get();
      for (var doc in friendsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        friendsUids.add(data['uid2'] as String);
      }

      // Fetch friends where user is uid2
      final reverseFriendsSnapshot =
          await _friendship.where('uid2', isEqualTo: uid).get();
      for (var doc in reverseFriendsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        friendsUids.add(data['uid1'] as String);
      }

      List<HiveUserModel> friends = [];
      final box = await Hive.openBox<HiveUserModel>('user_friends_box');
      for (String friendUid in friendsUids) {
        final userSnapshot = await _users.doc(friendUid).get();
        if (userSnapshot.exists) {
          final userData = userSnapshot.data() as Map<String, dynamic>;
          final hiveUserModel = HiveUserModel.fromMap(userData);
          friends.add(hiveUserModel);
          box.put(friendUid, hiveUserModel);
        }
      }
      return friends;
    }
    return [];
  }
}

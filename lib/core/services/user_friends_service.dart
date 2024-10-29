import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:logger/logger.dart';

class UserFriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //REFERENCE ALL THE USERS FRIENDS
  CollectionReference get _friendships =>
      _firestore.collection(FirebaseConstants.friendshipCollection);

  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  //FETCH FRIENDS BY USER
  Future<void> fetchFriendsByUser(UserModel? userData) async {
    try {
      if (userData != null) {
        final results = await Future.wait([
          _friendships.where('uid1', isEqualTo: userData.uid).get(),
          _friendships.where('uid2', isEqualTo: userData.uid).get(),
        ]);

        final documents = results.expand((result) => result.docs).toList();
        final friendUids = documents.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['uid1'] == userData.uid ? data['uid2'] : data['uid1'];
        }).toList();

        if (friendUids.isEmpty) {
          Constants.friends = [];
        }

        final friendQuery =
            await _users.where(FieldPath.documentId, whereIn: friendUids).get();

        Constants.friends = friendQuery.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return UserModel.fromMap(data);
        }).toList();
      } else {
        Constants.friends = [];
      }
    } catch (e) {
      Logger().e(e);
    }
  }
}

import 'package:hash_balance/models/user_model.dart';

class UserProfileDataModel {
  final List<UserModel> friends;
  final List<UserModel> followers;
  final List<UserModel> following;
  UserProfileDataModel({
    required this.friends,
    required this.followers,
    required this.following,
  });

  UserProfileDataModel copyWith({
    List<UserModel>? friends,
    List<UserModel>? followers,
    List<UserModel>? following,
    List<UserModel>? pendingFriendRequests,
  }) {
    return UserProfileDataModel(
      friends: friends ?? this.friends,
      followers: followers ?? this.followers,
      following: following ?? this.following,
    );
  }

  factory UserProfileDataModel.fromMap(Map<String, dynamic> map) {
    return UserProfileDataModel(
      friends: List<UserModel>.from(
        (map['friends'] as List<int>).map<UserModel>(
          (x) => UserModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      followers: List<UserModel>.from(
        (map['followers'] as List<int>).map<UserModel>(
          (x) => UserModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      following: List<UserModel>.from(
        (map['following'] as List<int>).map<UserModel>(
          (x) => UserModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  @override
  String toString() {
    return 'UserProfileDataModel(friends: $friends, followers: $followers, following: $following)';
  }
}

import 'package:hash_balance/models/friendship_request_model.dart';
import 'package:hash_balance/models/user_model.dart';

class FriendRequesterDataModel {
  final FriendRequest friendRequest;
  final UserModel requester;

  FriendRequesterDataModel({
    required this.friendRequest,
    required this.requester,
  });

  factory FriendRequesterDataModel.fromMap(Map<String, dynamic> map) {
    return FriendRequesterDataModel(
      friendRequest: FriendRequest.fromMap(map['friendRequest']),
      requester: UserModel.fromMap(map['requester']),
    );
  }
}

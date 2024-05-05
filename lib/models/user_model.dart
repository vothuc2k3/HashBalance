import 'package:flutter/foundation.dart';

class UserModel {
  final String name;
  final String profileImage;
  final String bannerImage;
  final String uid;
  final bool isAuthenticated;
  final int activityPoint;
  final List<String> achivements;
  UserModel({
    required this.name,
    required this.profileImage,
    required this.bannerImage,
    required this.uid,
    required this.isAuthenticated,
    required this.activityPoint,
    required this.achivements,
  });

  UserModel copyWith({
    String? name,
    String? profileImage,
    String? bannerImage,
    String? uid,
    bool? isAuthenticated,
    int? activityPoint,
    List<String>? achivements,
  }) {
    return UserModel(
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      bannerImage: bannerImage ?? this.bannerImage,
      uid: uid ?? this.uid,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      activityPoint: activityPoint ?? this.activityPoint,
      achivements: achivements ?? this.achivements,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'profileImage': profileImage,
      'bannerImage': bannerImage,
      'uid': uid,
      'isAuthenticated': isAuthenticated,
      'activityPoint': activityPoint,
      'achivements': achivements,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] as String,
      profileImage: map['profileImage'] as String,
      bannerImage: map['bannerImage'] as String,
      uid: map['uid'] as String,
      isAuthenticated: map['isAuthenticated'] as bool,
      activityPoint: map['activityPoint'] as int,
      achivements:
          (map['achivements'] != null && map['achivements'] is List<dynamic>)
              ? List<String>.from(map['achivements'] as List<dynamic>)
              : [],
    );
  }

  @override
  String toString() {
    return 'UserModel(name: $name, profileImage: $profileImage, bannerImage: $bannerImage, uid: $uid, isAuthenticated: $isAuthenticated, activityPoint: $activityPoint, achivements: $achivements)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.profileImage == profileImage &&
        other.bannerImage == bannerImage &&
        other.uid == uid &&
        other.isAuthenticated == isAuthenticated &&
        other.activityPoint == activityPoint &&
        listEquals(other.achivements, achivements);
  }

  @override
  int get hashCode {
    return name.hashCode ^
        profileImage.hashCode ^
        bannerImage.hashCode ^
        uid.hashCode ^
        isAuthenticated.hashCode ^
        activityPoint.hashCode ^
        achivements.hashCode;
  }
}

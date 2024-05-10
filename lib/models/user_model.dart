import 'package:flutter/foundation.dart';

class UserModel {
  final String email;
  final String name;
  final String uid;
  final String profileImage;
  final String bannerImage;
  final bool isAuthenticated;
  final int activityPoint;
  final List<String> achivements;
  UserModel({
    required this.email,
    required this.name,
    required this.uid,
    required this.profileImage,
    required this.bannerImage,
    required this.isAuthenticated,
    required this.activityPoint,
    required this.achivements,
  });

  UserModel copyWith({
    String? email,
    String? name,
    String? uid,
    String? profileImage,
    String? bannerImage,
    bool? isAuthenticated,
    int? activityPoint,
    List<String>? achivements,
  }) {
    return UserModel(
      email: email ?? this.email,
      name: name ?? this.name,
      uid: uid ?? this.uid,
      profileImage: profileImage ?? this.profileImage,
      bannerImage: bannerImage ?? this.bannerImage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      activityPoint: activityPoint ?? this.activityPoint,
      achivements: achivements ?? this.achivements,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'name': name,
      'uid': uid,
      'profileImage': profileImage,
      'bannerImage': bannerImage,
      'isAuthenticated': isAuthenticated,
      'activityPoint': activityPoint,
      'achivements': achivements,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] as String,
      name: map['name'] as String,
      uid: map['uid'] as String,
      profileImage: map['profileImage'] as String,
      bannerImage: map['bannerImage'] as String,
      isAuthenticated: map['isAuthenticated'] as bool,
      activityPoint: map['activityPoint'] as int,
      achivements: List<String>.from(
        (map['achivements'] as List<String>),
      ),
    );
  }

  @override
  String toString() {
    return 'UserModel(email: $email, name: $name, uid: $uid, profileImage: $profileImage, bannerImage: $bannerImage, isAuthenticated: $isAuthenticated, activityPoint: $activityPoint, achivements: $achivements)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.email == email &&
        other.name == name &&
        other.uid == uid &&
        other.profileImage == profileImage &&
        other.bannerImage == bannerImage &&
        other.isAuthenticated == isAuthenticated &&
        other.activityPoint == activityPoint &&
        listEquals(other.achivements, achivements);
  }

  @override
  int get hashCode {
    return email.hashCode ^
        name.hashCode ^
        uid.hashCode ^
        profileImage.hashCode ^
        bannerImage.hashCode ^
        isAuthenticated.hashCode ^
        activityPoint.hashCode ^
        achivements.hashCode;
  }
}

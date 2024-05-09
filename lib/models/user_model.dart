import 'package:flutter/foundation.dart';

class UserModel {
  final String? email;
  final String? password;
  final String name;
  final String profileImage;
  final String bannerImage;
  final String? uid;
  final bool isAuthenticated;
  final int activityPoint;
  final List<String> achivements;
  UserModel({
    this.email,
    this.password,
    required this.name,
    required this.profileImage,
    required this.bannerImage,
    this.uid,
    required this.isAuthenticated,
    required this.activityPoint,
    required this.achivements,
  });

  UserModel copyWith({
    String? email,
    String? password,
    String? name,
    String? profileImage,
    String? bannerImage,
    String? uid,
    bool? isAuthenticated,
    int? activityPoint,
    List<String>? achivements,
  }) {
    return UserModel(
      email: email ?? this.email,
      password: password ?? this.password,
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
      'email': email,
      'password': password,
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
      email: map['email'] != null ? map['email'] as String : null,
      password: map['password'] != null ? map['password'] as String : null,
      name: map['name'] as String,
      profileImage: map['profileImage'] as String,
      bannerImage: map['bannerImage'] as String,
      uid: map['uid'] != null ? map['uid'] as String : null,
      isAuthenticated: map['isAuthenticated'] as bool,
      activityPoint: map['activityPoint'] as int,
      achivements: List<String>.from(
        (map['achivements'] as List<String>),
      ),
    );
  }

  @override
  String toString() {
    return 'UserModel(email: $email, password: $password, name: $name, profileImage: $profileImage, bannerImage: $bannerImage, uid: $uid, isAuthenticated: $isAuthenticated, activityPoint: $activityPoint, achivements: $achivements)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.email == email &&
        other.password == password &&
        other.name == name &&
        other.profileImage == profileImage &&
        other.bannerImage == bannerImage &&
        other.uid == uid &&
        other.isAuthenticated == isAuthenticated &&
        other.activityPoint == activityPoint &&
        listEquals(other.achivements, achivements);
  }

  @override
  int get hashCode {
    return email.hashCode ^
        password.hashCode ^
        name.hashCode ^
        profileImage.hashCode ^
        bannerImage.hashCode ^
        uid.hashCode ^
        isAuthenticated.hashCode ^
        activityPoint.hashCode ^
        achivements.hashCode;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserModel {
  final String email;
  String? password;
  final String name;
  String uid;
  final Timestamp createdAt;
  final String profileImage;
  final String bannerImage;
  final bool isAuthenticated;
  final bool isRestricted;
  final int activityPoint;
  final List<String> achivements;
  int? hashAge;
  UserModel({
    required this.email,
    this.password,
    required this.name,
    required this.uid,
    required this.createdAt,
    required this.profileImage,
    required this.bannerImage,
    required this.isRestricted,
    required this.isAuthenticated,
    required this.activityPoint,
    required this.achivements,
    this.hashAge,
  });

  UserModel copyWith({
    String? email,
    String? password,
    String? name,
    String? uid,
    Timestamp? createdAt,
    String? profileImage,
    String? bannerImage,
    bool? isAuthenticated,
    int? activityPoint,
    List<String>? achivements,
    int? hashAge,
    bool? isRestricted,
  }) {
    return UserModel(
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      profileImage: profileImage ?? this.profileImage,
      bannerImage: bannerImage ?? this.bannerImage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      activityPoint: activityPoint ?? this.activityPoint,
      achivements: achivements ?? this.achivements,
      hashAge: hashAge ?? this.hashAge,
      isRestricted: isRestricted ?? this.isRestricted,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'password': password,
      'name': name,
      'uid': uid,
      'createdAt': createdAt,
      'profileImage': profileImage,
      'bannerImage': bannerImage,
      'isAuthenticated': isAuthenticated,
      'activityPoint': activityPoint,
      'achivements': achivements,
      'hashAge': hashAge,
      'isRestricted': isRestricted,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] as String,
      password: map['password'] != null ? map['password'] as String : null,
      name: map['name'] as String,
      uid: map['uid'] as String,
      createdAt: map['createdAt'] as Timestamp,
      profileImage: map['profileImage'] as String,
      bannerImage: map['bannerImage'] as String,
      isRestricted: map['isRestricted'] as bool,
      isAuthenticated: map['isAuthenticated'] as bool,
      activityPoint: map['activityPoint'] as int,
      hashAge: map['hashAge'] as int,
      achivements: List<String>.from(
        (map['achivements'] as List<String>),
      ),
    );
  }

  @override
  String toString() {
    return 'UserModel(email: $email, password: $password, name: $name, uid: $uid, createdAt: $createdAt, profileImage: $profileImage, bannerImage: $bannerImage, isAuthenticated: $isAuthenticated, activityPoint: $activityPoint, achivements: $achivements, hashAge: $hashAge)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.email == email &&
        other.password == password &&
        other.name == name &&
        other.uid == uid &&
        other.createdAt == createdAt &&
        other.profileImage == profileImage &&
        other.bannerImage == bannerImage &&
        other.isAuthenticated == isAuthenticated &&
        other.activityPoint == activityPoint &&
        other.hashAge == hashAge &&
        other.isRestricted == isRestricted &&
        listEquals(other.achivements, achivements);
  }

  @override
  int get hashCode {
    return email.hashCode ^
        password.hashCode ^
        name.hashCode ^
        uid.hashCode ^
        createdAt.hashCode ^
        profileImage.hashCode ^
        bannerImage.hashCode ^
        isAuthenticated.hashCode ^
        activityPoint.hashCode ^
        hashAge.hashCode ^
        isRestricted.hashCode ^
        achivements.hashCode;
  }
}

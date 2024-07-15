// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String email;
  final String name;
  final String uid;
  final Timestamp createdAt;
  final String profileImage;
  final String bannerImage;
  final bool isAuthenticated;
  final bool isRestricted;
  final int activityPoint;
  final int? hashAge;
  final String? bio;
  final String? description;

  UserModel({
    required this.email,
    required this.name,
    required this.uid,
    required this.createdAt,
    required this.profileImage,
    required this.bannerImage,
    required this.isAuthenticated,
    required this.isRestricted,
    required this.activityPoint,
    this.hashAge,
    this.bio,
    this.description,
  });

  UserModel copyWith({
    String? email,
    String? name,
    String? uid,
    Timestamp? createdAt,
    String? profileImage,
    String? bannerImage,
    bool? isAuthenticated,
    bool? isRestricted,
    int? activityPoint,
    int? hashAge,
    String? bio,
    String? description,
  }) {
    return UserModel(
      email: email ?? this.email,
      name: name ?? this.name,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      profileImage: profileImage ?? this.profileImage,
      bannerImage: bannerImage ?? this.bannerImage,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isRestricted: isRestricted ?? this.isRestricted,
      activityPoint: activityPoint ?? this.activityPoint,
      hashAge: hashAge ?? this.hashAge,
      bio: bio ?? this.bio,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'name': name,
      'uid': uid,
      'createdAt': createdAt,
      'profileImage': profileImage,
      'bannerImage': bannerImage,
      'isAuthenticated': isAuthenticated,
      'isRestricted': isRestricted,
      'activityPoint': activityPoint,
      'hashAge': hashAge,
      'bio': bio,
      'description': description,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] as String,
      name: map['name'] as String,
      uid: map['uid'] as String,
      createdAt: map['createdAt'] as Timestamp,
      profileImage: map['profileImage'] as String,
      bannerImage: map['bannerImage'] as String,
      isAuthenticated: map['isAuthenticated'] as bool,
      isRestricted: map['isRestricted'] as bool,
      activityPoint: map['activityPoint'] as int,
      hashAge: map['hashAge'] != null ? map['hashAge'] as int : null,
      bio: map['bio'] != null ? map['bio'] as String : null,
      description:
          map['description'] != null ? map['description'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UserModel(email: $email, name: $name, uid: $uid, createdAt: $createdAt, profileImage: $profileImage, bannerImage: $bannerImage, isAuthenticated: $isAuthenticated, isRestricted: $isRestricted, activityPoint: $activityPoint, hashAge: $hashAge, bio: $bio, description: $description)';
  }

  @override
  bool operator ==(covariant UserModel other) {
    if (identical(this, other)) return true;

    return other.email == email &&
        other.name == name &&
        other.uid == uid &&
        other.createdAt == createdAt &&
        other.profileImage == profileImage &&
        other.bannerImage == bannerImage &&
        other.isAuthenticated == isAuthenticated &&
        other.isRestricted == isRestricted &&
        other.activityPoint == activityPoint &&
        other.hashAge == hashAge &&
        other.bio == bio &&
        other.description == description;
  }

  @override
  int get hashCode {
    return email.hashCode ^
        name.hashCode ^
        uid.hashCode ^
        createdAt.hashCode ^
        profileImage.hashCode ^
        bannerImage.hashCode ^
        isAuthenticated.hashCode ^
        isRestricted.hashCode ^
        activityPoint.hashCode ^
        hashAge.hashCode ^
        bio.hashCode ^
        description.hashCode;
  }
}

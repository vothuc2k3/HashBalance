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
  final String? bio;
  final String? description;
  UserModel({
    required this.email,
    this.password,
    required this.name,
    required this.uid,
    required this.createdAt,
    required this.profileImage,
    required this.bannerImage,
    required this.isAuthenticated,
    required this.isRestricted,
    required this.activityPoint,
    required this.achivements,
    this.hashAge,
    this.bio,
    this.description,
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
    bool? isRestricted,
    int? activityPoint,
    List<String>? achivements,
    int? hashAge,
    String? bio,
    String? description,
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
      isRestricted: isRestricted ?? this.isRestricted,
      activityPoint: activityPoint ?? this.activityPoint,
      achivements: achivements ?? this.achivements,
      hashAge: hashAge ?? this.hashAge,
      bio: bio ?? this.bio,
      description: description ?? this.description,
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
      'isRestricted': isRestricted,
      'activityPoint': activityPoint,
      'achivements': achivements,
      'hashAge': hashAge,
      'bio': bio,
      'description': description,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] as String,
      password: map['password'] != null ? map['password'] as String : null,
      description:
          map['description'] != null ? map['description'] as String : null,
      bio: map['bio'] != null ? map['bio'] as String : null,
      name: map['name'] as String,
      uid: map['uid'] as String,
      createdAt: map['createdAt'] as Timestamp,
      profileImage: map['profileImage'] as String,
      bannerImage: map['bannerImage'] as String,
      isAuthenticated: map['isAuthenticated'] as bool,
      isRestricted: map['isRestricted'] as bool,
      activityPoint: map['activityPoint'] as int,
      achivements: List<String>.from(
        (map['achivements'] as List<String>),
      ),
    );
  }
  @override
  String toString() {
    return 'UserModel(email: $email, password: $password, name: $name, uid: $uid, createdAt: $createdAt, profileImage: $profileImage, bannerImage: $bannerImage, isAuthenticated: $isAuthenticated, isRestricted: $isRestricted, activityPoint: $activityPoint, achivements: $achivements, hashAge: $hashAge, bio: $bio, description: $description)';
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
        other.isRestricted == isRestricted &&
        other.activityPoint == activityPoint &&
        listEquals(other.achivements, achivements) &&
        other.hashAge == hashAge &&
        other.bio == bio &&
        other.description == description;
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
        isRestricted.hashCode ^
        activityPoint.hashCode ^
        achivements.hashCode ^
        hashAge.hashCode ^
        bio.hashCode ^
        description.hashCode;
  }
}

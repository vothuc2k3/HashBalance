import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Community {
  final String id;
  final String name;
  final String profileImage;
  final String bannerImage;
  final String type;
  final Timestamp createdAt;
  final bool containsExposureContents;
  final List<String> members;
  final List<String> moderators;
  Community({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.bannerImage,
    required this.type,
    required this.createdAt,
    required this.containsExposureContents,
    required this.members,
    required this.moderators,
  });

  Community copyWith({
    String? id,
    String? name,
    String? profileImage,
    String? bannerImage,
    String? type,
    Timestamp? createdAt,
    bool? containsExposureContents,
    List<String>? members,
    List<String>? moderators,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      bannerImage: bannerImage ?? this.bannerImage,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      containsExposureContents:
          containsExposureContents ?? this.containsExposureContents,
      members: members ?? this.members,
      moderators: moderators ?? this.moderators,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'profileImage': profileImage,
      'bannerImage': bannerImage,
      'type': type,
      'createdAt': createdAt,
      'containsExposureContents': containsExposureContents,
      'members': members,
      'moderators': moderators,
    };
  }

  factory Community.fromMap(Map<String, dynamic> map) {
    return Community(
      id: map['id'] as String,
      name: map['name'] as String,
      profileImage: map['profileImage'] as String,
      bannerImage: map['bannerImage'] as String,
      type: map['type'] as String,
      createdAt: map['createdAt'] as Timestamp,
      containsExposureContents: map['containsExposureContents'] as bool,
      members: List<String>.from((map['members'] as List<String>)),
      moderators: List<String>.from((map['moderators'] as List<String>)),
    );
  }

  @override
  String toString() {
    return 'Community(id: $id, name: $name, profileImage: $profileImage, bannerImage: $bannerImage, type: $type, createdAt: $createdAt, containsExposureContents: $containsExposureContents, members: $members, moderators: $moderators)';
  }

  @override
  bool operator ==(covariant Community other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.profileImage == profileImage &&
        other.bannerImage == bannerImage &&
        other.type == type &&
        other.createdAt == createdAt &&
        other.containsExposureContents == containsExposureContents &&
        listEquals(other.members, members) &&
        listEquals(other.moderators, moderators);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        profileImage.hashCode ^
        bannerImage.hashCode ^
        type.hashCode ^
        createdAt.hashCode ^
        containsExposureContents.hashCode ^
        members.hashCode ^
        moderators.hashCode;
  }

  factory Community.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Community(
      name: data['name'] as String,
      members: List<String>.from(data['members'] ?? ['']),
      id: data['id'] as String,
      profileImage: data['profileImage'] as String,
      bannerImage: data['bannerImage'] as String,
      type: data['type'] as String,
      createdAt: data['createdAt'] as Timestamp,
      containsExposureContents: data['containsExposureContents'] as bool,
      moderators: List<String>.from(data['moderators'] ?? ['']),
    );
  }

  int get membersCount => members.length;
}

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Community {
  final String id;
  final String name;
  final String description;
  final String profileImage;
  final String bannerImage;
  final String type;
  final bool containsExposureContents;
  final Timestamp createdAt;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.profileImage,
    required this.bannerImage,
    required this.type,
    required this.containsExposureContents,
    required this.createdAt,
  });

  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? profileImage,
    String? bannerImage,
    String? type,
    bool? containsExposureContents,
    Timestamp? createdAt,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      profileImage: profileImage ?? this.profileImage,
      bannerImage: bannerImage ?? this.bannerImage,
      type: type ?? this.type,
      containsExposureContents:
          containsExposureContents ?? this.containsExposureContents,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'profileImage': profileImage,
      'bannerImage': bannerImage,
      'type': type,
      'containsExposureContents': containsExposureContents,
      'createdAt': createdAt,
    };
  }

  factory Community.fromMap(Map<String, dynamic> map) {
    return Community(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      profileImage: map['profileImage'] as String,
      bannerImage: map['bannerImage'] as String,
      type: map['type'] as String,
      containsExposureContents: map['containsExposureContents'] as bool,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  @override
  String toString() {
    return 'Community(id: $id, name: $name, description: $description, profileImage: $profileImage, bannerImage: $bannerImage, type: $type, containsExposureContents: $containsExposureContents, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Community other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.description == description &&
        other.profileImage == profileImage &&
        other.bannerImage == bannerImage &&
        other.type == type &&
        other.containsExposureContents == containsExposureContents &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        profileImage.hashCode ^
        bannerImage.hashCode ^
        type.hashCode ^
        containsExposureContents.hashCode ^
        createdAt.hashCode;
  }

  String toJson() => json.encode(toMap());

  factory Community.fromJson(String source) =>
      Community.fromMap(json.decode(source) as Map<String, dynamic>);
}

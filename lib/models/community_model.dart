// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Community {
  final String id;
  final String name;
  final String profileImage;
  final String bannerImage;
  final String type;
  final Timestamp createdAt;
  final bool containsExposureContents;
  Community({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.bannerImage,
    required this.type,
    required this.createdAt,
    required this.containsExposureContents,
  });

  Community copyWith({
    String? id,
    String? name,
    String? profileImage,
    String? bannerImage,
    String? type,
    Timestamp? createdAt,
    bool? containsExposureContents,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      bannerImage: bannerImage ?? this.bannerImage,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      containsExposureContents: containsExposureContents ?? this.containsExposureContents,
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
    );
  }

  @override
  String toString() {
    return 'Community(id: $id, name: $name, profileImage: $profileImage, bannerImage: $bannerImage, type: $type, createdAt: $createdAt, containsExposureContents: $containsExposureContents)';
  }

  @override
  bool operator ==(covariant Community other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.name == name &&
      other.profileImage == profileImage &&
      other.bannerImage == bannerImage &&
      other.type == type &&
      other.createdAt == createdAt &&
      other.containsExposureContents == containsExposureContents;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      profileImage.hashCode ^
      bannerImage.hashCode ^
      type.hashCode ^
      createdAt.hashCode ^
      containsExposureContents.hashCode;
  }

  factory Community.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Community(
      name: data['name'] as String,
      id: data['id'] as String,
      profileImage: data['profileImage'] as String,
      bannerImage: data['bannerImage'] as String,
      type: data['type'] as String,
      createdAt: data['createdAt'] as Timestamp,
      containsExposureContents: data['containsExposureContents'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory Community.fromJson(String source) => Community.fromMap(json.decode(source) as Map<String, dynamic>);
}

import 'package:flutter/foundation.dart';

class GamingCommunityModel {
  final String id;
  final String name;
  final String profileImage;
  final String bannerImage;
  final List<String> members;
  final List<String> mods;
  GamingCommunityModel({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.bannerImage,
    required this.members,
    required this.mods,
  });

  GamingCommunityModel copyWith({
    String? id,
    String? name,
    String? profileImage,
    String? bannerImage,
    List<String>? members,
    List<String>? mods,
  }) {
    return GamingCommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      bannerImage: bannerImage ?? this.bannerImage,
      members: members ?? this.members,
      mods: mods ?? this.mods,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'profileImage': profileImage,
      'bannerImage': bannerImage,
      'members': members,
      'mods': mods,
    };
  }

  factory GamingCommunityModel.fromMap(Map<String, dynamic> map) {
    return GamingCommunityModel(
      id: map['id'] as String,
      name: map['name'] as String,
      profileImage: map['profileImage'] as String,
      bannerImage: map['bannerImage'] as String,
      members: List<String>.from((map['members'] as List<String>)),
      mods: List<String>.from(
        (map['mods'] as List<String>),
      ),
    );
  }

  @override
  String toString() {
    return 'GamingCommunityModel(id: $id, name: $name, profileImage: $profileImage, bannerImage: $bannerImage, members: $members, mods: $mods)';
  }

  @override
  bool operator ==(covariant GamingCommunityModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.profileImage == profileImage &&
        other.bannerImage == bannerImage &&
        listEquals(other.members, members) &&
        listEquals(other.mods, mods);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        profileImage.hashCode ^
        bannerImage.hashCode ^
        members.hashCode ^
        mods.hashCode;
  }
}

import 'package:flutter/foundation.dart';

class Community {
  final String id;
  final String name;
  final String profileImage;
  final String bannerImage;
  final String type;
  final bool containsExposureContents;
  final List<String> members;
  final List<String> mods;
  Community({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.bannerImage,
    required this.type,
    required this.containsExposureContents,
    required this.members,
    required this.mods,
  });

  Community copyWith({
    String? id,
    String? name,
    String? profileImage,
    String? bannerImage,
    String? type,
    bool? containsExposureContents,
    List<String>? members,
    List<String>? mods,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      bannerImage: bannerImage ?? this.bannerImage,
      type: type ?? this.type,
      containsExposureContents:
          containsExposureContents ?? this.containsExposureContents,
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
      'type': type,
      'containsExposureContents': containsExposureContents,
      'members': members,
      'mods': mods,
    };
  }

  factory Community.fromMap(Map<String, dynamic> map) {
    return Community(
      id: map['id'] as String,
      name: map['name'] as String,
      profileImage: map['profileImage'] as String,
      bannerImage: map['bannerImage'] as String,
      type: map['type'] as String,
      containsExposureContents: map['containsExposureContents'] as bool,
      members: (map['members'] as List<dynamic>)
          .map((item) => item.toString())
          .toList(),
      mods: (map['mods'] as List<dynamic>)
          .map((item) => item.toString())
          .toList(),
    );
  }

  @override
  String toString() {
    return 'Community(id: $id, name: $name, profileImage: $profileImage, bannerImage: $bannerImage, type: $type, containsExposureContents: $containsExposureContents, members: $members, mods: $mods)';
  }

  @override
  bool operator ==(covariant Community other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.profileImage == profileImage &&
        other.bannerImage == bannerImage &&
        other.type == type &&
        other.containsExposureContents == containsExposureContents &&
        listEquals(other.members, members) &&
        listEquals(other.mods, mods);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        profileImage.hashCode ^
        bannerImage.hashCode ^
        type.hashCode ^
        containsExposureContents.hashCode ^
        members.hashCode ^
        mods.hashCode;
  }
}

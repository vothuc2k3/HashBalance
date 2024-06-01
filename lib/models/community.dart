import 'package:cloud_firestore/cloud_firestore.dart';

class Community {
  final String name;
  final String profileImage;
  final String bannerImage;
  final int membersCount;
  final Timestamp createdAt;
  final String type;
  final bool containsExposureContents;
  Community({
    required this.name,
    required this.profileImage,
    required this.bannerImage,
    required this.membersCount,
    required this.createdAt,
    required this.type,
    required this.containsExposureContents,
  });

  Community copyWith({
    String? name,
    String? profileImage,
    String? bannerImage,
    int? membersCount,
    Timestamp? createdAt,
    String? type,
    bool? containsExposureContents,
    List<String>? mods,
  }) {
    return Community(
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      bannerImage: bannerImage ?? this.bannerImage,
      membersCount: membersCount ?? this.membersCount,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      containsExposureContents:
          containsExposureContents ?? this.containsExposureContents,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'profileImage': profileImage,
      'bannerImage': bannerImage,
      'membersCount': membersCount,
      'createdAt': createdAt,
      'type': type,
      'containsExposureContents': containsExposureContents,
    };
  }

  factory Community.fromMap(Map<String, dynamic> map) {
    return Community(
      name: map['name'] as String,
      profileImage: map['profileImage'] as String,
      bannerImage: map['bannerImage'] as String,
      membersCount: map['membersCount'] as int,
      createdAt: map['createdAt'] as Timestamp,
      type: map['type'] as String,
      containsExposureContents: map['containsExposureContents'] as bool,
    );
  }

  @override
  String toString() {
    return 'Community(name: $name, profileImage: $profileImage, bannerImage: $bannerImage, membersCount: $membersCount, createdAt: $createdAt, type: $type, containsExposureContents: $containsExposureContents)';
  }

  @override
  bool operator ==(covariant Community other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.profileImage == profileImage &&
        other.bannerImage == bannerImage &&
        other.membersCount == membersCount &&
        other.createdAt == createdAt &&
        other.type == type &&
        other.containsExposureContents == containsExposureContents;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        profileImage.hashCode ^
        bannerImage.hashCode ^
        membersCount.hashCode ^
        createdAt.hashCode ^
        type.hashCode ^
        containsExposureContents.hashCode;
  }
}

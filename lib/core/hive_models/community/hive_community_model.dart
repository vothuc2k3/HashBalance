import 'package:hive_flutter/hive_flutter.dart';

part 'hive_community_model.g.dart';

@HiveType(typeId: 1)
class HiveCommunityModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String profileImage;

  @HiveField(3)
  late String bannerImage;

  @HiveField(4)
  late String type;

  @HiveField(5)
  late bool containsExposureContents;

  @HiveField(6)
  String? pinPostId;

  HiveCommunityModel({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.bannerImage,
    required this.type,
    required this.containsExposureContents,
    this.pinPostId,
  });

  factory HiveCommunityModel.fromMap(Map<String, dynamic> map) {
    return HiveCommunityModel(
      id: map['id'] as String,
      name: map['name'] as String,
      profileImage: map['profileImage'] as String,
      bannerImage: map['bannerImage'] as String,
      type: map['type'] as String,
      containsExposureContents: map['containsExposureContents'] as bool,
      pinPostId: map['pinPostId'] as String?,
    );
  }
}

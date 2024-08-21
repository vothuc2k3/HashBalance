import 'package:hive_flutter/hive_flutter.dart';

part 'hive_user_model.g.dart';

@HiveType(typeId: 0)
class HiveUserModel extends HiveObject {
  @HiveField(0)
  late String email;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String uid;

  @HiveField(3)
  late String profileImage;

  @HiveField(4)
  late String bannerImage;

  @HiveField(5)
  late bool isAuthenticated;

  @HiveField(6)
  late bool isRestricted;

  @HiveField(7)
  late int activityPoint;

  @HiveField(8)
  late int? hashAge;

  @HiveField(9)
  late String? bio;

  @HiveField(10)
  late String? description;

  HiveUserModel({
    required this.email,
    required this.name,
    required this.uid,
    required this.profileImage,
    required this.bannerImage,
    required this.isAuthenticated,
    required this.isRestricted,
    required this.activityPoint,
    this.hashAge,
    this.bio,
    this.description,
  });

  factory HiveUserModel.fromMap(Map<String, dynamic> map) {
    return HiveUserModel(
      email: map['email'] as String,
      name: map['name'] as String,
      uid: map['uid'] as String,
      profileImage: map['profileImage'] as String,
      bannerImage: map['bannerImage'] as String,
      isAuthenticated: map['isAuthenticated'] as bool,
      isRestricted: map['isRestricted'] as bool,
      activityPoint: map['activityPoint'] as int,
      hashAge: map['hashAge'] as int?,
      bio: map['bio'] as String?,
      description: map['description'] as String?,
    );
  }
}

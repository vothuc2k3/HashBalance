// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_community_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveCommunityModelAdapter extends TypeAdapter<HiveCommunityModel> {
  @override
  final int typeId = 1;

  @override
  HiveCommunityModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveCommunityModel(
      id: fields[0] as String,
      name: fields[1] as String,
      profileImage: fields[2] as String,
      bannerImage: fields[3] as String,
      type: fields[4] as String,
      containsExposureContents: fields[5] as bool,
      pinPostId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCommunityModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.profileImage)
      ..writeByte(3)
      ..write(obj.bannerImage)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.containsExposureContents)
      ..writeByte(6)
      ..write(obj.pinPostId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveCommunityModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

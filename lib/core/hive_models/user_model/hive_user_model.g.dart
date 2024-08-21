// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveUserModelAdapter extends TypeAdapter<HiveUserModel> {
  @override
  final int typeId = 0;

  @override
  HiveUserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveUserModel(
      email: fields[0] as String,
      name: fields[1] as String,
      uid: fields[2] as String,
      profileImage: fields[3] as String,
      bannerImage: fields[4] as String,
      isAuthenticated: fields[5] as bool,
      isRestricted: fields[6] as bool,
      activityPoint: fields[7] as int,
      hashAge: fields[8] as int?,
      bio: fields[9] as String?,
      description: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveUserModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.email)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.uid)
      ..writeByte(3)
      ..write(obj.profileImage)
      ..writeByte(4)
      ..write(obj.bannerImage)
      ..writeByte(5)
      ..write(obj.isAuthenticated)
      ..writeByte(6)
      ..write(obj.isRestricted)
      ..writeByte(7)
      ..write(obj.activityPoint)
      ..writeByte(8)
      ..write(obj.hashAge)
      ..writeByte(9)
      ..write(obj.bio)
      ..writeByte(10)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveUserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

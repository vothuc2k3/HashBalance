// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserDevices {
  final String uid;
  final String deviceId;
  final Timestamp createdAt;
  UserDevices({
    required this.uid,
    required this.deviceId,
    required this.createdAt,
  });

  UserDevices copyWith({
    String? uid,
    String? deviceId,
    Timestamp? createdAt,
  }) {
    return UserDevices(
      uid: uid ?? this.uid,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'deviceId': deviceId,
      'createdAt': createdAt,
    };
  }

  factory UserDevices.fromMap(Map<String, dynamic> map) {
    return UserDevices(
      uid: map['uid'] as String,
      deviceId: map['deviceId'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserDevices.fromJson(String source) => UserDevices.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'UserDevices(uid: $uid, deviceId: $deviceId, createdAt: $createdAt)';

  @override
  bool operator ==(covariant UserDevices other) {
    if (identical(this, other)) return true;
  
    return 
      other.uid == uid &&
      other.deviceId == deviceId &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode => uid.hashCode ^ deviceId.hashCode ^ createdAt.hashCode;
}

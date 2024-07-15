// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserDevices {
  final String uid;
  final String deviceToken;
  final Timestamp createdAt;
  UserDevices({
    required this.uid,
    required this.deviceToken,
    required this.createdAt,
  });

  UserDevices copyWith({
    String? uid,
    String? deviceToken,
    Timestamp? createdAt,
  }) {
    return UserDevices(
      uid: uid ?? this.uid,
      deviceToken: deviceToken ?? this.deviceToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'deviceToken': deviceToken,
      'createdAt': createdAt,
    };
  }

  factory UserDevices.fromMap(Map<String, dynamic> map) {
    return UserDevices(
      uid: map['uid'] as String,
      deviceToken: map['deviceToken'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserDevices.fromJson(String source) => UserDevices.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'UserDevices(uid: $uid, deviceToken: $deviceToken, createdAt: $createdAt)';

  @override
  bool operator ==(covariant UserDevices other) {
    if (identical(this, other)) return true;
  
    return 
      other.uid == uid &&
      other.deviceToken == deviceToken &&
      other.createdAt == createdAt;
  }

  @override
  int get hashCode => uid.hashCode ^ deviceToken.hashCode ^ createdAt.hashCode;
}

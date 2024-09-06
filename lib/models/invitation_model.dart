import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Invitation {
  final String id;
  final String senderUid;
  final String receiverUid;
  final String type;
  final String communityId;
  final Timestamp createdAt;
  Invitation({
    required this.id,
    required this.senderUid,
    required this.receiverUid,
    required this.type,
    required this.communityId,
    required this.createdAt,
  });

  Invitation copyWith({
    String? id,
    String? senderUid,
    String? receiverUid,
    String? type,
    String? communityId,
    Timestamp? createdAt,
  }) {
    return Invitation(
      id: id ?? this.id,
      senderUid: senderUid ?? this.senderUid,
      receiverUid: receiverUid ?? this.receiverUid,
      type: type ?? this.type,
      communityId: communityId ?? this.communityId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'type': type,
      'communityId': communityId,
      'createdAt': createdAt,
    };
  }

  factory Invitation.fromMap(Map<String, dynamic> map) {
    return Invitation(
      id: map['id'] as String,
      senderUid: map['senderUid'] as String,
      receiverUid: map['receiverUid'] as String,
      type: map['type'] as String,
      communityId: map['communityId'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory Invitation.fromJson(String source) =>
      Invitation.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Invitation(id: $id, senderUid: $senderUid, receiverUid: $receiverUid, type: $type, communityId: $communityId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Invitation other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.senderUid == senderUid &&
        other.receiverUid == receiverUid &&
        other.type == type &&
        other.communityId == communityId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        senderUid.hashCode ^
        receiverUid.hashCode ^
        type.hashCode ^
        communityId.hashCode ^
        createdAt.hashCode;
  }
}

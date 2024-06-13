import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequest {
  final String id;
  final String requestUid;
  final String targetUid;
  final Timestamp createdAt;
  FriendRequest({
    required this.id,
    required this.requestUid,
    required this.targetUid,
    required this.createdAt,
  });

  FriendRequest copyWith({
    String? id,
    String? requestUid,
    String? targetUid,
    Timestamp? createdAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      requestUid: requestUid ?? this.requestUid,
      targetUid: targetUid ?? this.targetUid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'requestUid': requestUid,
      'targetUid': targetUid,
      'createdAt': createdAt,
    };
  }

  factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] as String,
      requestUid: map['requestUid'] as String,
      targetUid: map['targetUid'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  @override
  String toString() {
    return 'FriendRequest(id: $id, requestUid: $requestUid, targetUid: $targetUid, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant FriendRequest other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.requestUid == requestUid &&
        other.targetUid == targetUid &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        requestUid.hashCode ^
        targetUid.hashCode ^
        createdAt.hashCode;
  }
}

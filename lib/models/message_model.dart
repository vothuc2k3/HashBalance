import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String uid;
  final Timestamp createdAt;
  Message({
    required this.id,
    required this.text,
    required this.uid,
    required this.createdAt,
  });

  Message copyWith({
    String? id,
    String? text,
    String? uid,
    Timestamp? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'uid': uid,
      'createdAt': createdAt,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      text: map['text'] as String,
      uid: map['uid'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }
  @override
  String toString() {
    return 'Message(id: $id, text: $text, uid: $uid, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Message other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.text == text &&
        other.uid == uid &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ text.hashCode ^ uid.hashCode ^ createdAt.hashCode;
  }

  String toJson() => json.encode(toMap());

  factory Message.fromJson(String source) =>
      Message.fromMap(json.decode(source) as Map<String, dynamic>);
}

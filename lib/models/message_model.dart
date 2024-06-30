import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class Message {
  final String text;
  final String uid;
  final Timestamp createdAt;
  final List<String> seenBy;
  Message({
    required this.text,
    required this.uid,
    required this.createdAt,
    required this.seenBy,
  });

  Message copyWith({
    String? text,
    String? uid,
    Timestamp? createdAt,
    List<String>? seenBy,
  }) {
    return Message(
      text: text ?? this.text,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
      seenBy: seenBy ?? this.seenBy,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'text': text,
      'uid': uid,
      'createdAt': createdAt,
      'seenBy': seenBy,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      text: map['text'] as String,
      uid: map['uid'] as String,
      createdAt: map['createdAt'] as Timestamp,
      seenBy: List<String>.from((map['seenBy'] as List<String>)),
    );
  }
  @override
  String toString() {
    return 'Message(text: $text, uid: $uid, createdAt: $createdAt, seenBy: $seenBy)';
  }

  @override
  bool operator ==(covariant Message other) {
    if (identical(this, other)) return true;

    return other.text == text &&
        other.uid == uid &&
        other.createdAt == createdAt &&
        listEquals(other.seenBy, seenBy);
  }

  @override
  int get hashCode {
    return text.hashCode ^ uid.hashCode ^ createdAt.hashCode ^ seenBy.hashCode;
  }
}

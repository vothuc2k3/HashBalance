import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String text;
  final String uid;
  final Timestamp createdAt;
  Message({
    required this.text,
    required this.uid,
    required this.createdAt,
  });

  Message copyWith({
    String? text,
    String? uid,
    Timestamp? createdAt,
  }) {
    return Message(
      text: text ?? this.text,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'text': text,
      'uid': uid,
      'createdAt': createdAt,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      text: map['text'] as String,
      uid: map['uid'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }
  @override
  String toString() => 'Message(text: $text, uid: $uid, createdAt: $createdAt)';

  @override
  bool operator ==(covariant Message other) {
    if (identical(this, other)) return true;

    return other.text == text &&
        other.uid == uid &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => text.hashCode ^ uid.hashCode ^ createdAt.hashCode;
}

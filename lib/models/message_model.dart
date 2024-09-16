// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String? text;
  final String? image;
  final String? video;
  final String uid;
  final Timestamp createdAt;
  Message({
    required this.id,
    this.text,
    this.image,
    this.video,
    required this.uid,
    required this.createdAt,
  });

  Message copyWith({
    String? id,
    String? text,
    String? image,
    String? video,
    String? uid,
    Timestamp? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      image: image ?? this.image,
      video: video ?? this.video,
      uid: uid ?? this.uid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'text': text,
      'image': image,
      'video': video,
      'uid': uid,
      'createdAt': createdAt,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      text: map['text'] != null ? map['text'] as String : '',
      image: map['image'] != null ? map['image'] as String : '',
      video: map['video'] != null ? map['video'] as String : '',
      uid: map['uid'] as String,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  String toJson() => json.encode(toMap());

  factory Message.fromJson(String source) =>
      Message.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Message(id: $id, text: $text, image: $image, video: $video, uid: $uid, createdAt: $createdAt)';
  }

  @override
  bool operator ==(covariant Message other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.text == text &&
        other.image == image &&
        other.video == video &&
        other.uid == uid &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        text.hashCode ^
        image.hashCode ^
        video.hashCode ^
        uid.hashCode ^
        createdAt.hashCode;
  }
}

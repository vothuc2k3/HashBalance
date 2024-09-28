// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';

class Conversation {
  final String id;
  final String type;
  final List<String> participantUids;
  Conversation({
    required this.id,
    required this.type,
    required this.participantUids,
  });

  Conversation copyWith({
    String? id,
    String? type,
    String? status,
    List<String>? participantUids,
  }) {
    return Conversation(
      id: id ?? this.id,
      type: type ?? this.type,
      participantUids: participantUids ?? this.participantUids,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'participantUids': participantUids,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      type: map['type'] as String,
      participantUids:
          List<String>.from((map['participantUids'] as List<String>)),
    );
  }

  @override
  String toString() {
    return 'Conversation(id: $id, type: $type, participantUids: $participantUids)';
  }

  @override
  bool operator ==(covariant Conversation other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.type == type &&
        listEquals(other.participantUids, participantUids);
  }

  @override
  int get hashCode {
    return id.hashCode ^ type.hashCode ^ participantUids.hashCode;
  }

  String toJson() => json.encode(toMap());

  factory Conversation.fromJson(String source) =>
      Conversation.fromMap(json.decode(source) as Map<String, dynamic>);
}

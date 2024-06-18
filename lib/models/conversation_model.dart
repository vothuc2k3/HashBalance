import 'package:flutter/foundation.dart';

class Conversation {
  final String id;
  final List<String> participantUids;
  Conversation({
    required this.id,
    required this.participantUids,
  });

  Conversation copyWith({
    String? id,
    List<String>? participantUids,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantUids: participantUids ?? this.participantUids,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'participantUids': participantUids,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      participantUids:
          List<String>.from((map['participantUids'] as List<String>)),
    );
  }

  @override
  String toString() =>
      'Conversation(id: $id, participantUids: $participantUids)';

  @override
  bool operator ==(covariant Conversation other) {
    if (identical(this, other)) return true;

    return other.id == id && listEquals(other.participantUids, participantUids);
  }

  @override
  int get hashCode => id.hashCode ^ participantUids.hashCode;
}

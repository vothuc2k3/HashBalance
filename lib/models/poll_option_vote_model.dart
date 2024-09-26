import 'dart:convert';

class PollOptionVote {
  final String id;
  final String pollId;
  final String pollOptionId;
  final String uid;
  PollOptionVote({
    required this.id,
    required this.pollId,
    required this.pollOptionId,
    required this.uid,
  });

  PollOptionVote copyWith({
    String? id,
    String? pollId,
    String? pollOptionId,
    String? uid,
  }) {
    return PollOptionVote(
      id: id ?? this.id,
      pollId: pollId ?? this.pollId,
      pollOptionId: pollOptionId ?? this.pollOptionId,
      uid: uid ?? this.uid,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'pollId': pollId,
      'pollOptionId': pollOptionId,
      'uid': uid,
    };
  }

  factory PollOptionVote.fromMap(Map<String, dynamic> map) {
    return PollOptionVote(
      id: map['id'] as String,
      pollId: map['pollId'] as String,
      pollOptionId: map['pollOptionId'] as String,
      uid: map['uid'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PollOptionVote.fromJson(String source) => PollOptionVote.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PollOptionVote(id: $id, pollId: $pollId, pollOptionId: $pollOptionId, uid: $uid)';
  }

  @override
  bool operator ==(covariant PollOptionVote other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.pollId == pollId &&
      other.pollOptionId == pollOptionId &&
      other.uid == uid;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      pollId.hashCode ^
      pollOptionId.hashCode ^
      uid.hashCode;
  }
}

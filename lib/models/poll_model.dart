import 'dart:convert';

import 'package:flutter/foundation.dart';

class Poll {
  final String pollId;
  final String uid;
  final String question;
  final DateTime createdAt;
  final bool isMultipleChoice;
  final List<Map<String, dynamic>> options;

  Poll({
    required this.pollId,
    required this.uid,
    required this.question,
    required this.createdAt,
    this.isMultipleChoice = false,
    required this.options,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pollId': pollId,
      'uid': uid,
      'question': question,
      'createdAt': createdAt,
      'isMultipleChoice': isMultipleChoice,
      'options': options,
    };
  }

  factory Poll.fromMap(Map<String, dynamic> map) {
    return Poll(
      pollId: map['pollId'] as String,
      uid: map['uid'] as String,
      question: map['question'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      isMultipleChoice: map['isMultipleChoice'] as bool,
      options: List<Map<String, dynamic>>.from(
        (map['options'] as List<Map<String, dynamic>>)
            .map<Map<String, dynamic>>(
          (x) => x,
        ),
      ),
    );
  }

  Poll copyWith({
    String? pollId,
    String? uid,
    String? question,
    DateTime? createdAt,
    DateTime? endsAt,
    bool? isMultipleChoice,
    List<Map<String, dynamic>>? options,
  }) {
    return Poll(
      pollId: pollId ?? this.pollId,
      uid: uid ?? this.uid,
      question: question ?? this.question,
      createdAt: createdAt ?? this.createdAt,
      isMultipleChoice: isMultipleChoice ?? this.isMultipleChoice,
      options: options ?? this.options,
    );
  }

  String toJson() => json.encode(toMap());

  factory Poll.fromJson(String source) =>
      Poll.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Poll(pollId: $pollId, uid: $uid, question: $question, createdAt: $createdAt, isMultipleChoice: $isMultipleChoice, options: $options)';
  }

  @override
  bool operator ==(covariant Poll other) {
    if (identical(this, other)) return true;

    return other.pollId == pollId &&
        other.uid == uid &&
        other.question == question &&
        other.createdAt == createdAt &&
        other.isMultipleChoice == isMultipleChoice &&
        listEquals(other.options, options);
  }

  @override
  int get hashCode {
    return pollId.hashCode ^
        uid.hashCode ^
        question.hashCode ^
        createdAt.hashCode ^
        isMultipleChoice.hashCode ^
        options.hashCode;
  }
}

class PollOption {
  String optionId;
  String title;
  int voteCount;

  PollOption({
    required this.optionId,
    required this.title,
    this.voteCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'optionId': optionId,
      'title': title,
      'voteCount': voteCount,
    };
  }

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      optionId: map['optionId'],
      title: map['title'],
      voteCount: map['voteCount'] ?? 0,
    );
  }
}

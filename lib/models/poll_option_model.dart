import 'dart:convert';

class PollOption {
  final String id;
  final String pollId;
  final String option;

  PollOption({
    required this.id,
    required this.pollId,
    required this.option,
  });

  PollOption copyWith({
    String? id,
    String? pollId,
    String? option,
  }) {
    return PollOption(
      id: id ?? this.id,
      pollId: pollId ?? this.pollId,
      option: option ?? this.option,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'pollId': pollId,
      'option': option,
    };
  }

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      id: map['id'] as String,
      pollId: map['pollId'] as String,
      option: map['option'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory PollOption.fromJson(String source) =>
      PollOption.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'PollOption(id: $id, pollId: $pollId, option: $option)';

  @override
  bool operator ==(covariant PollOption other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.pollId == pollId &&
      other.option == option;
  }

  @override
  int get hashCode => id.hashCode ^ pollId.hashCode ^ option.hashCode;
}

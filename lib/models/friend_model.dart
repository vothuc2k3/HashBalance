class Friend {
  final String uid1;
  final String uid2;
  Friend({
    required this.uid1,
    required this.uid2,
  });

  Friend copyWith({
    String? uid1,
    String? uid2,
  }) {
    return Friend(
      uid1: uid1 ?? this.uid1,
      uid2: uid2 ?? this.uid2,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid1': uid1,
      'uid2': uid2,
    };
  }

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      uid1: map['uid1'] as String,
      uid2: map['uid2'] as String,
    );
  }

  @override
  String toString() => 'Friend(uid1: $uid1, uid2: $uid2)';

  @override
  bool operator ==(covariant Friend other) {
    if (identical(this, other)) return true;

    return other.uid1 == uid1 && other.uid2 == uid2;
  }

  @override
  int get hashCode => uid1.hashCode ^ uid2.hashCode;
}

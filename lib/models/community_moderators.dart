class CommunityModerators {
  final String uid;
  final String communityName;
  CommunityModerators({
    required this.uid,
    required this.communityName,
  });

  CommunityModerators copyWith({
    String? uid,
    String? communityName,
  }) {
    return CommunityModerators(
      uid: uid ?? this.uid,
      communityName: communityName ?? this.communityName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'communityName': communityName,
    };
  }

  factory CommunityModerators.fromMap(Map<String, dynamic> map) {
    return CommunityModerators(
      uid: map['uid'] as String,
      communityName: map['communityName'] as String,
    );
  }

  @override
  String toString() =>
      'CommunityModerators(uid: $uid, communityName: $communityName)';

  @override
  bool operator ==(covariant CommunityModerators other) {
    if (identical(this, other)) return true;

    return other.uid == uid && other.communityName == communityName;
  }

  @override
  int get hashCode => uid.hashCode ^ communityName.hashCode;
}

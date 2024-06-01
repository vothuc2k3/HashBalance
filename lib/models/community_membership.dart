class CommunityMembership {
  final String uid;
  final String communityName;
  CommunityMembership({
    required this.uid,
    required this.communityName,
  });

  CommunityMembership copyWith({
    String? uid,
    String? communityName,
  }) {
    return CommunityMembership(
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

  factory CommunityMembership.fromMap(Map<String, dynamic> map) {
    return CommunityMembership(
      uid: map['uid'] as String,
      communityName: map['communityName'] as String,
    );
  }

  @override
  String toString() =>
      'CommunityMembership(uid: $uid, communityName: $communityName)';

  @override
  bool operator ==(covariant CommunityMembership other) {
    if (identical(this, other)) return true;

    return other.uid == uid && other.communityName == communityName;
  }

  @override
  int get hashCode => uid.hashCode ^ communityName.hashCode;
}

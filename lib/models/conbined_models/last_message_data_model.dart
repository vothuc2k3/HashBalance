import 'dart:convert';

import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conversation_model.dart';
import 'package:hash_balance/models/message_model.dart';
import 'package:hash_balance/models/user_model.dart';

class LastMessageDataModel {
  final Conversation conversation;
  final Message message;
  final UserModel? targetUser;
  final UserModel? author;
  final Community? community;
  LastMessageDataModel({
    required this.conversation,
    required this.message,
    this.targetUser,
    this.author,
    this.community,
  });

  LastMessageDataModel copyWith({
    Conversation? conversation,
    Message? message,
    UserModel? author,
    Community? community,
    UserModel? targetUser,
  }) {
    return LastMessageDataModel(
      conversation: conversation ?? this.conversation,
      message: message ?? this.message,
      author: author ?? this.author,
      community: community ?? this.community,
      targetUser: targetUser ?? this.targetUser,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'conversation': conversation.toMap(),
      'message': message.toMap(),
      'author': author?.toMap(),
      'community': community?.toMap(),
      'targetUser': targetUser?.toMap(),
    };
  }

  factory LastMessageDataModel.fromMap(Map<String, dynamic> map) {
    return LastMessageDataModel(
      conversation:
          Conversation.fromMap(map['conversation'] as Map<String, dynamic>),
      message: Message.fromMap(map['message'] as Map<String, dynamic>),
      author: map['author'] != null
          ? UserModel.fromMap(map['author'] as Map<String, dynamic>)
          : null,
      community: map['community'] != null
          ? Community.fromMap(map['community'] as Map<String, dynamic>)
          : null,
      targetUser: map['targetUser'] != null
          ? UserModel.fromMap(map['targetUser'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory LastMessageDataModel.fromJson(String source) =>
      LastMessageDataModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LastMessageDataModel(conversation: $conversation, message: $message, author: $author, community: $community, targetUser: $targetUser)';
  }

  @override
  bool operator ==(covariant LastMessageDataModel other) {
    if (identical(this, other)) return true;

    return other.conversation == conversation &&
        other.message == message &&
        other.author == author &&
        other.community == community &&
        other.targetUser == targetUser;
  }

  @override
  int get hashCode {
    return conversation.hashCode ^
        message.hashCode ^
        author.hashCode ^
        community.hashCode ^
        targetUser.hashCode;
  }
}

import 'dart:convert';

import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conversation_model.dart';
import 'package:hash_balance/models/message_model.dart';
import 'package:hash_balance/models/user_model.dart';

class MessageDataModel {
  final Conversation conversation;
  final Message message;
  final UserModel? author;
  final Community? community;
  MessageDataModel({
    required this.conversation,
    required this.message,
    this.author,
    this.community,
  });

  MessageDataModel copyWith({
    Conversation? conversation,
    Message? message,
    UserModel? author,
    Community? community,
  }) {
    return MessageDataModel(
      conversation: conversation ?? this.conversation,
      message: message ?? this.message,
      author: author ?? this.author,
      community: community ?? this.community,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'conversation': conversation.toMap(),
      'message': message.toMap(),
      'author': author?.toMap(),
      'community': community?.toMap(),
    };
  }

  factory MessageDataModel.fromMap(Map<String, dynamic> map) {
    return MessageDataModel(
      conversation: Conversation.fromMap(map['conversation'] as Map<String,dynamic>),
      message: Message.fromMap(map['message'] as Map<String,dynamic>),
      author: map['author'] != null ? UserModel.fromMap(map['author'] as Map<String,dynamic>) : null,
      community: map['community'] != null ? Community.fromMap(map['community'] as Map<String,dynamic>) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory MessageDataModel.fromJson(String source) =>
      MessageDataModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MessageDataModel(conversation: $conversation, message: $message, author: $author, community: $community)';
  }

  @override
  bool operator ==(covariant MessageDataModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.conversation == conversation &&
      other.message == message &&
      other.author == author &&
      other.community == community;
  }

  @override
  int get hashCode {
    return conversation.hashCode ^
      message.hashCode ^
      author.hashCode ^
      community.hashCode;
  }
}

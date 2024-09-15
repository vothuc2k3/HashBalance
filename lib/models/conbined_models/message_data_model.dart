import 'package:hash_balance/models/message_model.dart';
import 'package:hash_balance/models/user_model.dart';

class MessageDataModel {
  final Message message;
  final UserModel author;
  MessageDataModel({
    required this.message,
    required this.author,
  });

  factory MessageDataModel.fromMap(Map<String, dynamic> map) {
    return MessageDataModel(
      message: Message.fromMap(map['message'] as Map<String, dynamic>),
      author: UserModel.fromMap(map['author'] as Map<String, dynamic>),
    );
  }

  @override
  String toString() => 'MessageDataModel(message: $message, author: $author)';
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/message_model.dart';

final messageRepositoryProvider = Provider((ref) {
  return MessageRepository(firestore: ref.read(firebaseFirestoreProvider));
});

class MessageRepository {
  final FirebaseFirestore _firestore;

  MessageRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  Stream<List<Message>?> loadMessages(String conversationId) {
    return _conversation
        .doc(conversationId)
        .collection('message')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
      (event) {
        if (event.docs.isEmpty) {
          return null;
        } else {
          final loadedMessages = event.docs;
          List<Message>? messages = [];
          for (var doc in loadedMessages) {
            final docData = doc.data();
            messages.add(
              Message(
                text: docData['text'] as String,
                uid: docData['uid'] as String,
                createdAt: docData['createdAt'] as Timestamp,
              ),
            );
          }
          return messages;
        }
      },
    );
  }

  //REFERENCES ALL THE CONVERSATIONS
  CollectionReference get _conversation =>
      _firestore.collection(FirebaseConstants.commentsCollection);
}

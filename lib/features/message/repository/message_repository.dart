import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/conversation_model.dart';
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
                id: docData['id'] as String,
                text: docData['text'] as String,
                uid: docData['uid'] as String,
                createdAt: docData['createdAt'] as Timestamp,
                seenBy: List<String>.from(docData['seenBy']),
              ),
            );
          }
          return messages;
        }
      },
    );
  }

  FutureVoid sendMessage(
    Message message,
    Conversation conversation,
  ) async {
    try {
      await _conversation.doc(conversation.id).set(conversation.toMap());
      await _conversation
          .doc(conversation.id)
          .collection('message')
          .doc()
          .set(message.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<List<Conversation>?> getCurrentUserConversation(String uid) {
    return _conversation
        .where('participantUids', arrayContains: uid)
        .snapshots()
        .map(
      (event) {
        if (event.docs.isEmpty) {
          return null;
        } else {
          List<Conversation> conversations = [];
          for (var doc in event.docs) {
            final data = doc.data() as Map<String, dynamic>;
            conversations.add(
              Conversation(
                id: data['id'] as String,
                participantUids: List<String>.from(data['participantUids']),
              ),
            );
          }
          return conversations;
        }
      },
    );
  }

  Stream<Message> getLastMessageByConversation(String id) {
    return _conversation
        .doc(id)
        .collection('message')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map(
      (event) {
        final List<Message> message = [];
        for (var doc in event.docs) {
          final data = doc.data();
          message.add(
            Message(
              id: data['id'] as String,
              text: data['text'] as String,
              uid: data['uid'] as String,
              createdAt: data['createdAt'] as Timestamp,
              seenBy: List<String>.from(data['seenBy']),
            ),
          );
        }
        return message.first;
      },
    );
  }

  //MARK THE MESSAGE AS SEEN
  Future<void> markAsRead(String conversationId, String seenUid) async {
    final messagesRef = _firestore
        .collection('conversation')
        .doc(conversationId)
        .collection('message');
    final querySnapshot = await messagesRef.get();
    for (var doc in querySnapshot.docs) {
      List<dynamic> seenBy = doc['seenBy'] as List<dynamic>;
      if (!seenBy.contains(seenUid)) {
        seenBy.add(seenUid);
        await doc.reference.update({'seenBy': seenBy});
      }
    }
  }

  //REFERENCES ALL THE CONVERSATIONS
  CollectionReference get _conversation =>
      _firestore.collection(FirebaseConstants.conversationCollection);
}
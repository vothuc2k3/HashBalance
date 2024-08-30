import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conversation_model.dart';
import 'package:hash_balance/models/message_data_model.dart';
import 'package:hash_balance/models/message_model.dart';
import 'package:hash_balance/models/user_model.dart';

final messageRepositoryProvider = Provider((ref) {
  return MessageRepository(firestore: ref.read(firebaseFirestoreProvider));
});

class MessageRepository {
  final FirebaseFirestore _firestore;

  MessageRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //REFERENCES ALL THE CONVERSATIONS
  CollectionReference get _conversation =>
      _firestore.collection(FirebaseConstants.conversationCollection);
  //REFERENCES ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //REFERENCES ALL THE COMMUNITIES
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);

  Stream<List<Message>?> loadPrivateMessages(String conversationId) {
    return _conversation
        .doc(conversationId)
        .collection(FirebaseConstants.messagesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
      (event) {
        if (event.docs.isEmpty) {
          return null;
        } else {
          List<Message> messages = event.docs.map(
            (doc) {
              return Message.fromMap(doc.data());
            },
          ).toList();
          return messages;
        }
      },
    );
  }

  Stream<List<Message>> loadCommunityMessage(String communityId) {
    return _conversation
        .doc(communityId)
        .collection(FirebaseConstants.messagesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
      (event) {
        List<Message> messages = event.docs.map(
          (doc) {
            return Message.fromMap(doc.data());
          },
        ).toList();
        return messages;
      },
    );
  }

  FutureVoid sendPrivateMessage(
      Message message, Conversation conversation) async {
    try {
      final conversationDoc = await _conversation.doc(conversation.id).get();
      if (conversationDoc.exists) {
        await _conversation
            .doc(conversation.id)
            .collection(FirebaseConstants.messagesCollection)
            .doc(message.id)
            .set(message.toMap());
      } else {
        await _conversation.doc(conversation.id).set(conversation.toMap());
        await _conversation
            .doc(conversation.id)
            .collection(FirebaseConstants.messagesCollection)
            .doc(message.id)
            .set(message.toMap());
      }
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  FutureVoid sendCommunityMessage(
    Message message,
    Conversation conversation,
  ) async {
    try {
      final conversationDoc = await _conversation.doc(conversation.id).get();

      if (conversationDoc.exists) {
        final data = conversationDoc.data() as Map<String, dynamic>;
        final existingConversation = Conversation(
          id: data['id'] as String,
          type: data['type'] as String,
          participantUids: List<String>.from(data['participantUids']),
        );
        final participantUids = existingConversation.participantUids;

        if (!participantUids.contains(message.uid)) {
          await _conversation.doc(conversation.id).update({
            'participantUids': FieldValue.arrayUnion([message.uid]),
          });
        }

        // Lưu tin nhắn vào collection messages
        await _conversation
            .doc(conversation.id)
            .collection(FirebaseConstants.messagesCollection)
            .doc(message.id)
            .set(message.toMap());
      } else {
        // Tạo cuộc trò chuyện mới nếu chưa tồn tại
        await _conversation.doc(conversation.id).set(conversation.toMap());

        // Lưu tin nhắn vào collection messages
        await _conversation
            .doc(conversation.id)
            .collection(FirebaseConstants.messagesCollection)
            .doc(message.id)
            .set(message.toMap());
      }

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
                type: data['type'] as String,
                participantUids: List<String>.from(data['participantUids']),
              ),
            );
          }
          return conversations;
        }
      },
    );
  }

  Stream<MessageDataModel> getLastMessageByConversation(String conversationId) {
    final conversationDocRef = _conversation.doc(conversationId);
    return conversationDocRef
        .collection(FirebaseConstants.messagesCollection)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .asyncMap(
      (event) async {
        final messageDoc = event.docs.first.data();
        final conversationDoc = await conversationDocRef.get();
        final conversationData = conversationDoc.data() as Map<String, dynamic>;
        final conversation = Conversation(
          id: conversationId,
          type: conversationData['type'] as String,
          participantUids: List<String>.from(
            conversationData['participantUids'],
          ),
        );
        final message = Message(
          id: messageDoc['id'] as String,
          text: messageDoc['text'] as String,
          uid: messageDoc['uid'] as String,
          createdAt: messageDoc['createdAt'] as Timestamp,
        );
        if (conversation.type == 'Community') {
          final communityDoc = await _communities.doc(conversationId).get();
          final community =
              Community.fromMap(communityDoc.data() as Map<String, dynamic>);
          return MessageDataModel(
              conversation: conversation,
              message: message,
              community: community);
        } else {
          final authorDoc = await _users.doc(message.uid).get();
          final author =
              UserModel.fromMap(authorDoc.data() as Map<String, dynamic>);
          return MessageDataModel(
            conversation: conversation,
            message: message,
            author: author,
          );
        }
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
}

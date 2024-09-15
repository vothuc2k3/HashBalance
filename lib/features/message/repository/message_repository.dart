import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/message_data_model.dart';
import 'package:hash_balance/models/conversation_model.dart';
import 'package:hash_balance/models/conbined_models/last_message_data_model.dart';
import 'package:hash_balance/models/message_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:logger/logger.dart';

final messageRepositoryProvider = Provider((ref) {
  return MessageRepository(firestore: ref.read(firebaseFirestoreProvider));
});

class MessageRepository {
  final FirebaseFirestore _firestore;
  final _logger = Logger();

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

  //LOAD INITIAL PRIVATE MESSAGES
  Stream<List<Message>?> loadInitialPrivateMessages(String conversationId) {
    return _conversation
        .doc(conversationId)
        .collection(FirebaseConstants.messageCollection)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
      (event) {
        if (event.docs.isEmpty) {
          return null;
        } else {
          List<Message> messages = event.docs.map((doc) {
            return Message.fromMap(doc.data());
          }).toList();
          return messages;
        }
      },
    );
  }

  //LOAD MORE PRIVATE MESSAGES
  Future<List<Message>?> loadMorePrivateMessages(
    String conversationId,
    Message lastMessage,
  ) async {
    _logger.d(lastMessage.toString());
    final createdAt = lastMessage.createdAt;
    final querySnapshot = await _conversation
        .doc(conversationId)
        .collection(FirebaseConstants.messageCollection)
        .orderBy('createdAt', descending: true)
        .startAfter([createdAt])
        .limit(10)
        .get();

    if (querySnapshot.docs.isEmpty) {
      _logger.d('NULL MESSAGES');
      return null;
    } else {
      List<Message> messages = querySnapshot.docs.map((doc) {
        return Message.fromMap(doc.data());
      }).toList();
      _logger.d(messages.toString());
      return messages;
    }
  }

  //LOAD COMMUNITY MESSAGES
  Stream<List<MessageDataModel>?> loadInitialCommunityMessages(
      String communityId) {
    return _conversation
        .doc(communityId)
        .collection(FirebaseConstants.messageCollection)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .asyncMap(
      (event) async {
        if (event.docs.isEmpty) {
          return null;
        } else {
          List<MessageDataModel> messagesDataList = [];
          final messages = event.docs.map((doc) {
            return Message.fromMap(doc.data());
          }).toList();
          for (var message in messages) {
            final authorDoc = await _users.doc(message.uid).get();
            final author =
                UserModel.fromMap(authorDoc.data() as Map<String, dynamic>);
            final messageData = MessageDataModel(
              message: message,
              author: author,
            );
            messagesDataList.add(messageData);
          }
          return messagesDataList;
        }
      },
    );
  }

  //LOAD MORE COMMUNITY MESSAGES
  Future<List<Message>?> loadMoreCommunityMessages(
    String conversationId,
    Message lastMessage,
  ) async {
    _logger.d(lastMessage.toString());
    final createdAt = lastMessage.createdAt;
    final querySnapshot = await _conversation
        .doc(conversationId)
        .collection(FirebaseConstants.messageCollection)
        .orderBy('createdAt', descending: true)
        .startAfter([createdAt])
        .limit(10)
        .get();

    if (querySnapshot.docs.isEmpty) {
      _logger.d('NULL MESSAGES');
      return null;
    } else {
      List<Message> messages = querySnapshot.docs.map((doc) {
        return Message.fromMap(doc.data());
      }).toList();
      _logger.d(messages.toString());
      return messages;
    }
  }

  //SEND PRIVATE MESSAGE
  FutureVoid sendPrivateMessage(
      Message message, Conversation conversation) async {
    try {
      final conversationDoc = await _conversation.doc(conversation.id).get();
      if (conversationDoc.exists) {
        await _conversation
            .doc(conversation.id)
            .collection(FirebaseConstants.messageCollection)
            .doc(message.id)
            .set(message.toMap());
      } else {
        await _conversation.doc(conversation.id).set(conversation.toMap());
        await _conversation
            .doc(conversation.id)
            .collection(FirebaseConstants.messageCollection)
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

  //SEND COMMUNITY MESSAGE
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

        await _conversation
            .doc(conversation.id)
            .collection(FirebaseConstants.messageCollection)
            .doc(message.id)
            .set(message.toMap());
      } else {
        await _conversation.doc(conversation.id).set(conversation.toMap());
        await _conversation
            .doc(conversation.id)
            .collection(FirebaseConstants.messageCollection)
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

  //GET CURRENT USER CONVERSATIONS
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

  //GET LAST MESSAGE BY CONVERSATION
  Stream<LastMessageDataModel> getLastMessageByConversation(
      Conversation c, String currentUid) {
    final conversationDocRef = _conversation.doc(c.id);
    return conversationDocRef
        .collection(FirebaseConstants.messageCollection)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .asyncMap(
      (event) async {
        final messageDoc = event.docs.first.data();
        final conversationDoc = await conversationDocRef.get();
        final conversationData = conversationDoc.data() as Map<String, dynamic>;
        final conversation = Conversation(
          id: c.id,
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
          final communityDoc = await _communities.doc(c.id).get();
          final community =
              Community.fromMap(communityDoc.data() as Map<String, dynamic>);
          return LastMessageDataModel(
            conversation: conversation,
            message: message,
            community: community,
          );
        } else {
          final authorDoc = await _users.doc(message.uid).get();
          final author =
              UserModel.fromMap(authorDoc.data() as Map<String, dynamic>);
          String targetUid = conversation.participantUids
              .firstWhere((uid) => uid != currentUid);
          final targetUserDoc = await _users.doc(targetUid).get();
          final targetUser =
              UserModel.fromMap(targetUserDoc.data() as Map<String, dynamic>);
          return LastMessageDataModel(
            conversation: conversation,
            message: message,
            author: author,
            targetUser: targetUser,
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

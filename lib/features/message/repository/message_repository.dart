import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/archived_conversation_model.dart';
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
  //REFERENCES ALL THE ARCHIVED CONVERSATIONS
  CollectionReference get _archivedConversations =>
      _firestore.collection(FirebaseConstants.archivedConversationCollection);

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
    final querySnapshot = await _conversation
        .doc(conversationId)
        .collection(FirebaseConstants.messageCollection)
        .orderBy('createdAt', descending: true)
        .startAfter([lastMessage.createdAt])
        .limit(10)
        .get();
    if (querySnapshot.docs.isEmpty) {
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
        .limit(20)
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
          for (final message in messages) {
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
  Future<List<MessageDataModel>?> loadMoreCommunityMessages(
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
      return null;
    } else {
      List<MessageDataModel> messagesDataList = [];
      List<Message> messages = querySnapshot.docs.map((doc) {
        return Message.fromMap(doc.data());
      }).toList();
      for (final message in messages) {
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
  }

  //SEND PRIVATE MESSAGE
  Future<Either<Failures, void>> sendPrivateMessage({
    required Message message,
    required String conversationId,
    required String targetUid,
  }) async {
    try {
      final batch = _firestore.batch();
      final conversationRef = _conversation.doc(conversationId);
      final messageRef = conversationRef
          .collection(FirebaseConstants.messageCollection)
          .doc(message.id);

      final conversationDoc = await conversationRef.get();

      if (conversationDoc.exists) {
        batch.set(messageRef, message.toMap());
      } else {
        final newConversation = Conversation(
          id: conversationId,
          type: 'Private',
          participantUids: [message.uid, targetUid],
        );

        batch.set(conversationRef, newConversation.toMap());
        batch.set(messageRef, message.toMap());
      }
      await batch.commit();

      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

//SEND COMMUNITY MESSAGE
  Future<Either<Failures, void>> sendCommunityMessage({
    required Message message,
    required String communityId,
  }) async {
    try {
      final conversationDoc = await _conversation.doc(communityId).get();
      final batch = _firestore.batch();
      if (conversationDoc.exists) {
        final data = conversationDoc.data() as Map<String, dynamic>;
        final existingConversation = Conversation(
          id: data['id'] as String,
          type: data['type'] as String,
          participantUids: List<String>.from(data['participantUids']),
        );

        if (!existingConversation.participantUids.contains(message.uid)) {
          batch.update(_conversation.doc(communityId), {
            'participantUids': FieldValue.arrayUnion([message.uid]),
          });
        }
      } else {
        final newConversation = Conversation(
          id: communityId,
          type: 'Community',
          participantUids: [message.uid],
        );

        batch.set(_conversation.doc(communityId), newConversation.toMap());
      }
      batch.set(
        _conversation
            .doc(communityId)
            .collection(FirebaseConstants.messageCollection)
            .doc(message.id),
        message.toMap(),
      );
      await batch.commit();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //GET CURRENT USER CONVERSATIONS
  Stream<List<Conversation>?> getCurrentUserConversations(String uid) {
    return _conversation
        .where('participantUids', arrayContains: uid)
        .snapshots()
        .asyncMap(
      (event) async {
        if (event.docs.isEmpty) {
          return null;
        } else {
          final archivedConversationDocs = await _archivedConversations
              .where('archivedBy', isEqualTo: uid)
              .get();
          List<String> archivedConversationIds = [];
          for (var doc in archivedConversationDocs.docs) {
            final data = doc.data() as Map<String, dynamic>;
            archivedConversationIds.add(data['conversationId'] as String);
          }
          List<Conversation> conversations = [];
          for (var doc in event.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final conversationId = data['id'] as String;
            if (!archivedConversationIds.contains(conversationId)) {
              conversations.add(
                Conversation(
                  id: data['id'] as String,
                  type: data['type'] as String,
                  participantUids: List<String>.from(data['participantUids']),
                ),
              );
            }
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

  Stream<List<Conversation>> getArchivedConversations({
    required String uid,
  }) {
    return _archivedConversations
        .where('archivedBy', isEqualTo: uid)
        .snapshots()
        .asyncMap(
      (event) async {
        if (event.docs.isEmpty) {
          return [];
        } else {
          List<Conversation> conversations = [];
          List<String> conversationIds = [];
          for (final doc in event.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final conversationId = data['conversationId'] as String;
            conversationIds.add(conversationId);
          }
          for (final conversationId in conversationIds) {
            final conversationDoc =
                await _conversation.doc(conversationId).get();
            final conversationData =
                conversationDoc.data() as Map<String, dynamic>;
            conversations.add(
              Conversation(
                id: conversationData['id'] as String,
                type: conversationData['type'] as String,
                participantUids: List<String>.from(
                  conversationData['participantUids'],
                ),
              ),
            );
          }
          return conversations;
        }
      },
    );
  }

  Future<Either<Failures, void>> archiveConversation({
    required ArchivedConversationModel archivedConversation,
  }) async {
    try {
      final batch = _firestore.batch();
      batch.set(_archivedConversations.doc(archivedConversation.id),
          archivedConversation.toMap());
      await batch.commit();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> unarchiveConversation({
    required String conversationId,
    required String uid,
  }) async {
    try {
      final batch = _firestore.batch();
      final archivedConversationDoc = await _archivedConversations
          .where('conversationId', isEqualTo: conversationId)
          .where('archivedBy', isEqualTo: uid)
          .get();
      if (archivedConversationDoc.docs.isNotEmpty) {
        batch.delete(archivedConversationDoc.docs.first.reference);
      } else {
        _logger.d('Conversation $conversationId not found');
      }
      await batch.commit();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}

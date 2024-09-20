import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/invitation_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final invitationRepositoryProvider = Provider((ref) {
  return InvitationRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

class InvitationRepository {
  final FirebaseFirestore _firestore;

  InvitationRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //REFERENCE ALL THE POSTS
  CollectionReference get _invitations =>
      _firestore.collection(FirebaseConstants.invitationCollection);

  //ADD A NEW INVITATION
  Future<Either<Failures, void>> addInvitation(Invitation invitation) async {
    try {
      // Check if an invitation with the same sender, receiver, and type already exists
      final querySnapshot = await _invitations
          .where('senderUid', isEqualTo: invitation.senderUid)
          .where('receiverUid', isEqualTo: invitation.receiverUid)
          .where('type', isEqualTo: invitation.type)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // If a similar invitation already exists, return an error or handle it accordingly
        return left(Failures('The invitation already exists'));
      }

      // If no duplicate is found, add the new invitation
      await _invitations.doc(invitation.id).set(invitation.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<Invitation?> fetchInvitation(
    String uid,
    String communityId,
  ) {
    return _invitations
        .where('receiverUid', isEqualTo: uid)
        .where('communityId', isEqualTo: communityId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      } else {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        return Invitation.fromMap(data);
      }
    });
  }

  Future<Either<Failures, void>> deleteInvitation(String invitationId) async {
    try {
      await _invitations.doc(invitationId).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}

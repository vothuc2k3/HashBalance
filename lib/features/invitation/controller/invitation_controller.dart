import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/invitation/repository/invitation_repository.dart';
import 'package:hash_balance/models/invitation_model.dart';

final invitationProvider = StreamProviderFamily((ref, String communityId) =>
    ref.watch(invitationControllerProvider).fetchInvitation(communityId));

final invitationControllerProvider = Provider((ref) {
  return InvitationController(
    ref: ref,
    invitationRepository: ref.read(invitationRepositoryProvider),
  );
});

class InvitationController {
  final Ref _ref;
  final InvitationRepository _invitationRepository;

  InvitationController({
    required Ref ref,
    required InvitationRepository invitationRepository,
  })  : _ref = ref,
        _invitationRepository = invitationRepository;

  FutureVoid addInvitation(
    String receiverUid,
    String type,
    String communityId,
  ) async {
    try {
      final currentUser = _ref.read(userProvider)!;
      final invitation = Invitation(
        id: await generateRandomId(),
        senderUid: currentUser.uid,
        receiverUid: receiverUid,
        type: type,
        communityId: communityId,
        createdAt: Timestamp.now(),
      );
      return await _invitationRepository.addInvitation(invitation);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<Invitation?> fetchInvitation(
    String communityId,
  ) {
    try {
      final currentUser = _ref.read(userProvider)!;
      return _invitationRepository.fetchInvitation(
        currentUser.uid,
        communityId,
      );
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Future<Either<Failures, void>> deleteInvitation(String invitationId) async {
    try {
      await _invitationRepository.deleteInvitation(invitationId);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}

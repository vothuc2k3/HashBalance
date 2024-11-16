import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/models/livestream_model.dart';
import 'package:uuid/uuid.dart';

import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/features/livestream/repository/livestream_repository.dart';
import 'package:hash_balance/models/livestream_comment_model.dart';

final listenToLivestreamProvider =
    StreamProvider.family<Livestream, String>((ref, livestreamId) {
  final livestreamController = ref.watch(livestreamControllerProvider);
  return livestreamController.listenToLivestream(livestreamId);
});

final communityLivestreamProvider =
    StreamProvider.family<Livestream?, String>((ref, communityId) {
  final livestreamController = ref.watch(livestreamControllerProvider);
  return livestreamController.getCommunityLivestream(communityId);
});

final getLivestreamCommentsProvider =
    StreamProvider.family<List<LivestreamComment>, String>((ref, streamId) {
  final livestreamController = ref.watch(livestreamControllerProvider);
  return livestreamController.getLivestreamComments(streamId);
});

final livestreamControllerProvider =
    Provider<LivestreamController>((ref) => LivestreamController(
          livestreamRepository: ref.read(livestreamRepositoryProvider),
        ));

class LivestreamController {
  final LivestreamRepository _livestreamRepository;

  LivestreamController({required LivestreamRepository livestreamRepository})
      : _livestreamRepository = livestreamRepository;

  Stream<List<LivestreamComment>> getLivestreamComments(String streamId) {
    return _livestreamRepository.getLivestreamComments(streamId);
  }

  Future<Either<Failures, void>> createLivestreamComment({
    required String uid,
    required String streamId,
    required String content,
  }) async {
    return _livestreamRepository.createLivestreamComment(LivestreamComment(
      id: const Uuid().v4(),
      uid: uid,
      streamId: streamId,
      content: content,
      createdAt: Timestamp.now(),
    ));
  }

  Future<Either<Failures, Livestream>> createLivestream({
    required String communityId,
    required String content,
    required String uid,
  }) async {
    final result = await _livestreamRepository.fetchAgoraToken(communityId);
    return await result.fold(
      (l) {
        return left(l);
      },
      (token) async {
        final livestream = Livestream(
          id: const Uuid().v4(),
          communityId: communityId,
          content: content,
          uid: uid,
          status: 'on_going',
          agoraToken: token,
          createdAt: Timestamp.now(),
        );
        final createResult = await _livestreamRepository.createLivestream(livestream);
        return createResult.fold(
          (failure) => left(failure),
          (_) => right(livestream),
        );
      },
    );
  }

  Stream<Livestream?> getCommunityLivestream(String communityId) {
    return _livestreamRepository.getCommunityLivestream(communityId);
  }

  Future<Either<Failures, void>> endLivestream(String livestreamId) async {
    return _livestreamRepository.endLivestream(livestreamId);
  }

  Stream<Livestream> listenToLivestream(String livestreamId) {
    return _livestreamRepository.listenToLivestream(livestreamId);
  }
}

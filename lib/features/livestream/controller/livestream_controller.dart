import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/models/livestream_model.dart';
import 'package:uuid/uuid.dart';

import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/features/livestream/repository/livestream_repository.dart';
import 'package:hash_balance/models/livestream_comment_model.dart';

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
}

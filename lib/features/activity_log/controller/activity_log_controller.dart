import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/features/activity_log/repository/activity_log_repository.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/models/activity_log_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

final activityLogStreamProvider = StreamProvider<List<ActivityLogModel>>((ref) {
  return ref.watch(activityLogControllerProvider.notifier).getActivityLog();
});

final activityLogControllerProvider =
    StateNotifierProvider<ActivityLogController, bool>(
  (ref) {
    return ActivityLogController(
      activityLogRepository: ref.read(activityLogRepositoryProvider),
      ref: ref,
    );
  },
);

class ActivityLogController extends StateNotifier<bool> {
  final ActivityLogRepository _activityLogRepository;
  final Ref _ref;

  ActivityLogController({
    required ActivityLogRepository activityLogRepository,
    required Ref ref,
  })  : _activityLogRepository = activityLogRepository,
        _ref = ref,
        super(false);

  Future<Either<Failures, void>> clearActivityLogs() async {
    state = true;
    final result = await _activityLogRepository.clearActivityLogs();
    state = false;
    return result;
  }

  void addUpvoteActivityLog({
    required String postAuthorName,
    required String communityName,
  }) async {
    final currentUser = _ref.read(userProvider)!;
    final activityLog = ActivityLogModel(
      id: const Uuid().v4(),
      uid: currentUser.uid,
      activityType: Constants.activityLogTypeUpvote,
      title: 'Upvote a post',
      message: Constants.getActivityLogUpvoteMessage(
        postAuthorName: postAuthorName,
        communityName: communityName,
      ),
      createdAt: Timestamp.now(),
    );
    await _activityLogRepository.addActivityLog(activityLog);
  }

  void addDownvoteActivityLog({
    required String postAuthorName,
    required String communityName,
  }) async {
    final currentUser = _ref.read(userProvider)!;
    final activityLog = ActivityLogModel(
      id: const Uuid().v4(),
      uid: currentUser.uid,
      activityType: Constants.activityLogTypeDownvote,
      title: 'Downvote a post',
      message: Constants.getActivityLogDownvoteMessage(
        postAuthorName: postAuthorName,
        communityName: communityName,
      ),
      createdAt: Timestamp.now(),
    );
    await _activityLogRepository.addActivityLog(activityLog);
  }

  Stream<List<ActivityLogModel>> getActivityLog() {
    final currentUser = _ref.read(userProvider)!;
    return _activityLogRepository.getActivityLog(uid: currentUser.uid);
  }
}

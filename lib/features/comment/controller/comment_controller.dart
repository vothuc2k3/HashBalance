import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';

import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/features/activity_log/controller/activity_log_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/repository/comment_repository.dart';
import 'package:hash_balance/features/push_notification/controller/push_notification_controller.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';
import 'package:hash_balance/features/user_devices/controller/user_device_controller.dart';
import 'package:hash_balance/features/perspective_api/controller/perspective_api_controller.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/conbined_models/comment_data_model.dart';
import 'package:hash_balance/models/notification_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:uuid/uuid.dart';

final getCommentVoteStatusProvider =
    StreamProvider.family((ref, String commentId) {
  return ref
      .watch(commentControllerProvider.notifier)
      .getCommentVoteStatus(commentId);
});

final getCommentVoteCountProvider =
    StreamProvider.family((ref, String commentId) {
  return ref
      .watch(commentControllerProvider.notifier)
      .getCommentVoteCount(commentId);
});

final getPostCommentsProvider = StreamProvider.family((ref, String postId) {
  return ref.watch(commentControllerProvider.notifier).getPostComments(postId);
});

final commentControllerProvider =
    StateNotifierProvider<CommentController, bool>(
  (ref) => CommentController(
    commentRepository: ref.read(commentRepositoryProvider),
    pushNotificationController:
        ref.read(pushNotificationControllerProvider.notifier),
    notificationController: ref.read(notificationControllerProvider.notifier),
    userDeviceController: ref.read(userDeviceControllerProvider),
    perspectiveApiController: ref.read(perspectiveApiControllerProvider),
    activityLogController: ref.read(activityLogControllerProvider.notifier),
    ref: ref,
  ),
);

class CommentController extends StateNotifier<bool> {
  final CommentRepository _commentRepository;
  final PushNotificationController _pushNotificationController;
  final NotificationController _notificationController;
  final UserDeviceController _userDeviceController;
  final PerspectiveApiController _perspectiveApiController;
  final ActivityLogController _activityLogController;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  CommentController({
    required CommentRepository commentRepository,
    required PushNotificationController pushNotificationController,
    required NotificationController notificationController,
    required UserDeviceController userDeviceController,
    required PerspectiveApiController perspectiveApiController,
    required ActivityLogController activityLogController,
    required Ref ref,
  })  : _commentRepository = commentRepository,
        _pushNotificationController = pushNotificationController,
        _notificationController = notificationController,
        _userDeviceController = userDeviceController,
        _perspectiveApiController = perspectiveApiController,
        _activityLogController = activityLogController,
        _ref = ref,
        super(false);

  //COMMENT
  Future<Either<Failures, void>> comment(
    Post post,
    String postAuthorName,
    String communityName,
    String? content,
    List<UserModel>? mentionUsers,
  ) async {
    try {
      final user = _ref.read(userProvider)!;

      if (content != null && content.isNotEmpty) {
        final errorMessage =
            await _perspectiveApiController.isCommentSafe(content);
        if (errorMessage.isLeft()) {
          return errorMessage as Either<Failures, void>;
        }

        if (errorMessage.isRight() &&
            errorMessage.getOrElse((_) => null) != null) {
          return left(Failures(errorMessage.getOrElse((_) => '')!));
        }
      } else {
        return left(Failures('Comment cannot be empty'));
      }

      final comment = CommentModel(
        id: _uuid.v4(),
        uid: user.uid,
        postId: post.id,
        createdAt: Timestamp.now(),
        content: content,
        parentCommentId: '',
        mentionedUser: {
          for (var user in mentionUsers!) user.uid: user.name,
        },
      );
      final result = await _commentRepository.comment(comment);
      return result.fold(
        (l) => left(
          Failures(l.message),
        ),
        (r) async {
          _activityLogController.addCommentActivityLog(
            postAuthorName: postAuthorName,
            communityName: communityName,
          );
          if (comment.mentionedUser != null &&
              comment.mentionedUser!.isNotEmpty) {
            final notification = NotificationModel(
              id: _uuid.v4(),
              title: Constants.commentMentionTitle,
              message: Constants.getCommentMentionContent(user.name),
              type: Constants.commentMentionType,
              postId: post.id,
              senderUid: comment.uid,
              createdAt: Timestamp.now(),
              isRead: false,
            );
            for (var uid in comment.mentionedUser!.keys) {
              await _notificationController.addNotification(uid, notification);
              final deviceTokensResult =
                  await _userDeviceController.getUserDeviceTokens(uid);
              deviceTokensResult.fold(
                (l) => throw FirebaseException(
                  plugin: 'Firebase Exception',
                  message: l.message,
                ),
                (tokens) async {
                  await _pushNotificationController.sendPushNotification(
                    tokens,
                    Constants.getCommentMentionContent(user.name),
                    Constants.commentMentionTitle,
                    {
                      'type': Constants.commentMentionType,
                      'commentId': comment.id,
                      'postId': post.id,
                    },
                    Constants.commentMentionType,
                  );
                },
              );
            }
          }
          return right(null);
        },
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> deleteComment(String commentId) async {
    try {
      await _commentRepository.deleteComment(commentId);
      await _commentRepository.clearCommentVotes(commentId);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //FETCH ALL COMMENTS OF A POST
  Stream<List<CommentDataModel>?> getPostComments(String postId) {
    return _commentRepository.getPostComments(postId);
  }

  //DELETE A COMMENT
  Future<Either<Failures, void>> clearPostComments(String postId) async {
    return await _commentRepository.clearPostComments(postId);
  }

  Stream<bool?> getCommentVoteStatus(String commentId) {
    final currentUser = _ref.read(userProvider)!;
    return _commentRepository.getCommentVoteStatus(commentId, currentUser.uid);
  }

  Stream<Map<String, int>> getCommentVoteCount(String commentId) {
    return _commentRepository.getCommentVoteCount(commentId);
  }

  Future<Either<Failures, void>> clearCommentVotes(String commentId) async {
    return await _commentRepository.clearCommentVotes(commentId);
  }

  Future<Either<Failures, void>> editComment(
      String commentId, String content) async {
    return await _commentRepository.editComment(commentId, content);
  }
}

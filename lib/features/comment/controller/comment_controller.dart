import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/repository/comment_repository.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/comment_vote_model.dart';

final getRelevantCommentsByPostProvider =
    StreamProvider.family((ref, String postId) {
  return ref
      .read(commentControllerProvider.notifier)
      .getRelevantCommentsByPost(postId);
});

final getCommentVoteStatusProvider =
    StreamProvider.family((ref, String commentId) {
  return ref
      .read(commentControllerProvider.notifier)
      .getCommentVoteStatus(commentId);
});

final getCommentVoteCountProvider =
    StreamProvider.family((ref, String commentId) {
  return ref
      .read(commentControllerProvider.notifier)
      .getCommentVoteCount(commentId);
});

final getPostCommentCountProvider = StreamProvider.family((ref, String postId) {
  return ref
      .read(commentControllerProvider.notifier)
      .getPostCommentCount(postId);
});

final getTopCommentProvider = StreamProvider.family((ref, String postId) {
  return ref.read(commentControllerProvider.notifier).getTopComment(postId);
});

final getNewestCommentsByPostProvider =
    StreamProvider.family((ref, String postId) {
  return ref
      .watch(commentControllerProvider.notifier)
      .getNewestCommentsByPost(postId);
});

final getOldestCommentsByPostProvider =
    StreamProvider.family((ref, String postId) {
  return ref
      .watch(commentControllerProvider.notifier)
      .getOldestCommentsByPost(postId);
});

final commentControllerProvider =
    StateNotifierProvider<CommentController, bool>(
  (ref) => CommentController(
    commentRepository: ref.read(commentRepositoryProvider),
    ref: ref,
  ),
);

class CommentController extends StateNotifier<bool> {
  final CommentRepository _commentRepository;
  final Ref _ref;

  CommentController({
    required CommentRepository commentRepository,
    required Ref ref,
  })  : _commentRepository = commentRepository,
        _ref = ref,
        super(false);

  //COMMENT
  FutureString comment(
    String postId,
    String? content,
  ) async {
    state = true;
    try {
      final user = _ref.read(userProvider);
      final comment = Comment(
        uid: user!.uid,
        postId: postId,
        createdAt: Timestamp.now(),
        content: content,
        id: await generateRandomId(),
      );
      final result = await _commentRepository.comment(comment);
      return result.fold(
        (l) => left((Failures(l.message))),
        (r) => right('Comment Was Successfully Done!'),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  //VOTE THE COMMENT
  FutureVoid voteComment(String commentId, String postId, bool userVote) async {
    try {
      final currentUser = _ref.read(userProvider)!;
      final commentVoteModel = CommentVote(
        id: await generateRandomId(),
        commentId: commentId,
        postId: postId,
        uid: currentUser.uid,
        isUpvoted: userVote,
        createdAt: Timestamp.now(),
      );

      await _commentRepository.voteComment(commentVoteModel);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<Map<String, int>> getCommentVoteCount(String commentId) {
    final uid = _ref.read(userProvider)!.uid;
    return _commentRepository.getCommentVoteCount(commentId, uid);
  }

  //GET NEWEST COMMENTS BY POSTS
  Stream<List<Comment>> getNewestCommentsByPost(String postId) {
    try {
      return _commentRepository.getNewestCommentsByPost(postId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //GET OLDEST COMMENTS BY POSTS
  Stream<List<Comment>> getOldestCommentsByPost(String postId) {
    try {
      return _commentRepository.getOldestCommentsByPost(postId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //GET 1 TOP COMMENT
  Stream<Comment?> getTopComment(String postId) {
    try {
      return _commentRepository.getTopComment(postId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //GET POST COMMENT COUNT
  Stream<int> getPostCommentCount(String postId) {
    try {
      return _commentRepository.getPostCommentCount(postId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Stream<bool?> getCommentVoteStatus(String commentId) {
    try {
      final uid = _ref.read(userProvider)!.uid;
      return _commentRepository.getCommentVoteStatus(commentId, uid);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  // GET OLDEST COMMENTS BY POSTS
  Stream<List<Comment>> getRelevantCommentsByPost(String postId) {
    try {
      final list = _commentRepository.getRelevantCommentsByPost(postId);
      return list;
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }
}

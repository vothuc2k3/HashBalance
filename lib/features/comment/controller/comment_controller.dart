import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/repository/comment_repository.dart';
import 'package:hash_balance/models/comment_model.dart';

final getCommentUpvoteStatusProvider =
    StreamProvider.family((ref, String postId) {
  return ref.watch(commentControllerProvider.notifier).checkDidUpvote(postId);
});

final getCommentDownvoteStatusProvider =
    StreamProvider.family((ref, String postId) {
  return ref.watch(commentControllerProvider.notifier).checkDidDownvote(postId);
});

final getCommentUpvoteCountProvider =
    StreamProvider.family((ref, String postId) {
  return ref.watch(commentControllerProvider.notifier).getUpvotes(postId);
});

final getCommentDownvoteCountProvider =
    StreamProvider.family((ref, String postId) {
  return ref.watch(commentControllerProvider.notifier).getDownvotes(postId);
});

final commentCountProvider = StreamProvider.family((ref, String postId) {
  return ref.watch(commentControllerProvider.notifier).getCommentCount(postId);
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

final getRelevantCommentsByPostProvider =
    StreamProvider.family((ref, String postId) {
  return ref
      .watch(commentControllerProvider.notifier)
      .getRelevantCommentsByPost(postId);
});

final getTopCommentProvider = StreamProvider.family((ref, String postId) {
  return ref.watch(commentControllerProvider.notifier).getTopComment(postId);
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
        upvotes: ['empty'],
        downvotes: ['empty'],
        upvoteCount: 0,
        id: generateRandomId(),
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

  //GET OLDEST COMMENTS BY POSTS
  Stream<List<Comment>> getRelevantCommentsByPost(String postId) {
    try {
      return _commentRepository.getRelevantCommentsByPost(postId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //GET TOP COMMENT
  Stream<List<Comment>> getTopComment(String postId) {
    try {
      return _commentRepository.getTopComment(postId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //GET COMMENT COUNT
  Stream<int> getCommentCount(String postId) {
    try {
      return _commentRepository.getCommentCount(postId);
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //UPVOTE A COMMENT
  FutureVoid upvote(String commentId, String authorUid) async {
    try {
      final user = _ref.watch(userProvider);
      final result =
          await _commentRepository.upvote(commentId, user!.uid, authorUid);
      return result.fold(
        (l) {
          return left(Failures(l.message));
        },
        (r) {
          return right(null);
        },
      );
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  //DOWNVOTE A COMMENT
  FutureVoid downvote(String commentId, String authorUid) async {
    try {
      final user = _ref.watch(userProvider);
      final result =
          await _commentRepository.downvote(commentId, user!.uid, authorUid);
      return result.fold(
        (l) {
          return left(Failures(l.message));
        },
        (r) {
          return right(null);
        },
      );
    } on FirebaseException catch (e) {
      throw Failures(e.message!);
    } catch (e) {
      throw Failures(e.toString());
    }
  }

  Stream<bool> checkDidUpvote(String commentId) {
    final user = _ref.read(userProvider);
    return _commentRepository.checkDidUpvote(commentId, user!.uid);
  }

  Stream<int> getUpvotes(String commentId) {
    return _commentRepository.getUpvotes(commentId);
  }

  Stream<bool> checkDidDownvote(String commentId) {
    final user = _ref.read(userProvider);
    return _commentRepository.checkDidDownvote(commentId, user!.uid);
  }

  Stream<int> getDownvotes(String commentId) {
    return _commentRepository.getDownvotes(commentId);
  }
}

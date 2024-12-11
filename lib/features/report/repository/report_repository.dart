import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/community_membership_model.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/comment_report_model.dart';
import 'package:hash_balance/models/conbined_models/community_report_model.dart';
import 'package:hash_balance/models/conbined_models/post_report_model.dart';
import 'package:hash_balance/models/conbined_models/user_report_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/report_model.dart';
import 'package:hash_balance/models/user_model.dart';

final reportRepositoryProvider = Provider(
    (ref) => ReportRepository(firestore: ref.read(firebaseFirestoreProvider)));

class ReportRepository {
  final FirebaseFirestore _firestore;

  const ReportRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //REFERENCE ALL THE REPORTS
  CollectionReference get _reports =>
      _firestore.collection(FirebaseConstants.reportCollection);
  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //REFERENCE ALL THE POSTS
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
  //REFERENCE ALL THE COMMENTS
  CollectionReference get _comments =>
      _firestore.collection(FirebaseConstants.commentsCollection);
  //REFERENCE ALL THE COMMUNITIES
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
  //REFERENCE ALL THE MEMBERSHIPS
  CollectionReference get _memberships =>
      _firestore.collection(FirebaseConstants.communityMembershipCollection);

  Future<Either<Failures, void>> addReport(Report report) async {
    try {
      await _reports.doc(report.id).set(report.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<List<Report>> fetchCommunityReports(String communityId) {
    return _reports
        .where('communityId', isEqualTo: communityId)
        .snapshots()
        .map((event) {
      List<Report> reports = <Report>[];
      for (final doc in event.docs) {
        final data = doc.data() as Map<String, dynamic>;
        reports.add(Report.fromMap(data));
      }
      return reports;
    });
  }

  Stream<PostReportModel> fetchPostReportData(Report report) {
    return _users.doc(report.reporterUid).snapshots().asyncMap((event) async {
      final reporter = UserModel.fromMap(event.data() as Map<String, dynamic>);
      final reportedPostDoc = await _posts.doc(report.reportedPostId).get();
      final reportedPost =
          Post.fromMap(reportedPostDoc.data() as Map<String, dynamic>);
      final postOwnerDoc = await _users.doc(reportedPost.uid).get();
      final postOwner =
          UserModel.fromMap(postOwnerDoc.data() as Map<String, dynamic>);
      return PostReportModel(
          post: reportedPost, reporter: reporter, postOwner: postOwner);
    });
  }

  Stream<CommentReportModel> fetchCommentReportData(Report report) {
    return _users.doc(report.reporterUid).snapshots().asyncMap((event) async {
      final reporter = UserModel.fromMap(event.data() as Map<String, dynamic>);
      final reportedCommentDoc =
          await _comments.doc(report.reportedCommentId).get();
      final reportedComment = CommentModel.fromMap(
          reportedCommentDoc.data() as Map<String, dynamic>);
      final commentOwnerDoc = await _users.doc(reportedComment.uid).get();
      final commentOwner =
          UserModel.fromMap(commentOwnerDoc.data() as Map<String, dynamic>);
      return CommentReportModel(
          comment: reportedComment,
          reporter: reporter,
          commentOwner: commentOwner);
    });
  }

  Stream<UserReportModel> fetchUserReportData(Report report) {
    return _users.doc(report.reporterUid).snapshots().asyncMap((event) async {
      final reporter = UserModel.fromMap(event.data() as Map<String, dynamic>);
      final reportedUserDoc = await _users.doc(report.reportedUid).get();
      final reportedUser =
          UserModel.fromMap(reportedUserDoc.data() as Map<String, dynamic>);
      return UserReportModel(reportedUser: reportedUser, reporter: reporter);
    });
  }

  Stream<CommunityReportModel> fetchCommunityReportData(Report report) {
    return _users.doc(report.reporterUid).snapshots().asyncMap((event) async {
      final reporter = UserModel.fromMap(event.data() as Map<String, dynamic>);
      final reportedCommunityDoc =
          await _communities.doc(report.reportedCommunityId).get();
      final reportedCommunity = Community.fromMap(
          reportedCommunityDoc.data() as Map<String, dynamic>);
      final ownerDoc =
          await _memberships.where('isCreator', isEqualTo: true).get();
      final membership = CommunityMembership.fromMap(
          ownerDoc.docs.first.data() as Map<String, dynamic>);
      final owner = await _users.doc(membership.uid).get();
      final ownerUser = UserModel.fromMap(owner.data() as Map<String, dynamic>);
      return CommunityReportModel(
        community: reportedCommunity,
        reporter: reporter,
        communityOwner: ownerUser,
      );
    });
  }

  Future<Either<Failures, void>> resolveReport(String reportId) async {
    try {
      await _reports.doc(reportId).update({'isResolved': true});
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}

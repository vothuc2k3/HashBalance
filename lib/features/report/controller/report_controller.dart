import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/report/repository/report_repository.dart';
import 'package:hash_balance/models/conbined_models/comment_report_model.dart';
import 'package:hash_balance/models/conbined_models/post_report_model.dart';
import 'package:hash_balance/models/report_model.dart';
import 'package:uuid/uuid.dart';

final commentReportDataProvider = StreamProviderFamily((ref, Report report) {
  return ref.watch(reportControllerProvider).fetchCommentReportData(report);
});

final postReportDataProvider = StreamProviderFamily((ref, Report report) {
  return ref.watch(reportControllerProvider).fetchPostReportData(report);
});

final communityReportsProvider =
    StreamProviderFamily((ref, String communityId) {
  return ref.watch(reportControllerProvider).fetchCommunityReports(communityId);
});

final reportControllerProvider = Provider(
  (ref) => ReportController(
    reportRepository: ref.read(reportRepositoryProvider),
    ref: ref,
  ),
);

class ReportController {
  final ReportRepository _reportRepository;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  const ReportController({
    required ReportRepository reportRepository,
    required Ref ref,
  })  : _reportRepository = reportRepository,
        _ref = ref;

  Future<Either<Failures, void>> addReport(
    String? reportedPostId,
    String? reportedCommentId,
    String? reportedUserId,
    String type,
    String? communityId,
    String message,
  ) async {
    try {
      final currentUser = _ref.read(userProvider)!;
      late Report report;
      switch (type) {
        case Constants.userReportType:
          report = Report(
            id: _uuid.v1(),
            type: type,
            reporterUid: currentUser.uid,
            communityId: communityId,
            reportedUid: reportedUserId,
            message: message,
            createdAt: Timestamp.now(),
            isResolved: false,
          );
          break;
        case Constants.postReportType:
          report = Report(
            id: _uuid.v1(),
            type: type,
            reporterUid: currentUser.uid,
            communityId: communityId,
            reportedPostId: reportedPostId,
            message: message,
            createdAt: Timestamp.now(),
            isResolved: false,
          );
          break;
        case Constants.commentReportType:
          report = Report(
            id: _uuid.v1(),
            type: type,
            reporterUid: currentUser.uid,
            communityId: communityId,
            reportedCommentId: reportedCommentId,
            message: message,
            createdAt: Timestamp.now(),
            isResolved: false,
          );
          break;
        default:
          return left(
            Failures(
              'Invalid report type',
            ),
          );
      }
      await _reportRepository.addReport(report);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<List<Report>> fetchCommunityReports(String communityId) {
    return _reportRepository.fetchCommunityReports(communityId);
  }

  Stream<PostReportModel> fetchPostReportData(Report report) {
    return _reportRepository.fetchPostReportData(report);
  }

  Stream<CommentReportModel> fetchCommentReportData(Report report) {
    return _reportRepository.fetchCommentReportData(report);
  }

  Future<Either<Failures, void>> resolveReport(String reportId) async {
    try {
      await _reportRepository.resolveReport(reportId);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}

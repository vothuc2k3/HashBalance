import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/admin_dashboard/controller/admin_dashboard_controller.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/moderation/screen/post_container/report_post_container.dart';
import 'package:hash_balance/features/report/controller/report_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/comment_report_model.dart';
import 'package:hash_balance/models/conbined_models/community_report_model.dart';
import 'package:hash_balance/models/conbined_models/post_report_model.dart';
import 'package:hash_balance/models/conbined_models/user_report_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/report_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:logger/logger.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final Report report;
  const ReportDetailScreen({super.key, required this.report});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  Widget _buildPostReport(PostReportModel report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ReportPostContainer(
          author: report.postOwner,
          post: report.post,
        ),
        const SizedBox(height: 16),
        _buildMessageWidget(),
      ],
    );
  }

  Widget _buildCommentReport(CommentReportModel report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Comment: ${report.comment.content}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 16),
        _buildMessageWidget(),
      ],
    );
  }

  Widget _buildUserReport(UserReportModel report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(report.reporter.profileImage),
              radius: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Reporter: ${report.reporter.name}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                    report.reportedUser.profileImage),
                radius: 25,
              ),
              const SizedBox(width: 8),
              Text(
                'Reported User: ${report.reportedUser.name}',
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildMessageWidget(),
      ],
    );
  }

  Widget _buildCommunityReport(CommunityReportModel report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Reported Community: ${report.community.name}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 16),
        _buildMessageWidget(),
      ],
    );
  }

  Widget _buildMessageWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Reason: ${widget.report.message}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue reportData;
    switch (widget.report.type) {
      case Constants.postReportType:
        reportData = ref.watch(postReportDataProvider(widget.report));
        break;
      case Constants.commentReportType:
        reportData = ref.watch(commentReportDataProvider(widget.report));
        break;
      case Constants.userReportType:
        reportData = ref.watch(userReportDataProvider(widget.report));
        break;
      case Constants.communityReportType:
        reportData = ref.watch(communityReportDataProvider(widget.report));
        break;
      default:
        reportData =
            AsyncValue.error('Unknown report type', StackTrace.current);
        break;
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: const Text('Report Details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'Time Since Reported: ${formatTime(widget.report.createdAt)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
      body: reportData.when(
        data: (report) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: ref.watch(preferredThemeProvider).first,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: report is PostReportModel
                          ? _buildPostReport(report)
                          : report is CommentReportModel
                              ? _buildCommentReport(report)
                              : report is UserReportModel
                                  ? _buildUserReport(report)
                                  : _buildCommunityReport(
                                      report as CommunityReportModel),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIgnoreButton(),
                      _buildActionButton(report),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: Loading()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  // Nút Ignore
  Widget _buildIgnoreButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        backgroundColor: ref.watch(preferredThemeProvider).approveButtonColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
      onPressed: () {
        _handleReportAction(false, null, null, null, null);
      },
      child: const Text(
        'Ignore',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Nút hành động
  Widget _buildActionButton(report) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        backgroundColor: ref.watch(preferredThemeProvider).declineButtonColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
      onPressed: () {
        if (report is PostReportModel) {
          _handleReportAction(true, report.post, null, null, null);
        } else if (report is CommentReportModel) {
          _handleReportAction(true, null, report.comment, null, null);
        } else if (report is UserReportModel) {
          _handleReportAction(true, null, null, report.reportedUser, null);
        } else if (report is CommunityReportModel) {
          _handleReportAction(true, null, null, null, report.community);
        }
      },
      child: Text(
        report is PostReportModel
            ? 'Delete post'
            : report is CommentReportModel
                ? 'Delete comment'
                : report is UserReportModel
                    ? 'Ban user'
                    : 'Delete community',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleReportAction(
    bool option,
    Post? post,
    CommentModel? comment,
    UserModel? reportedUser,
    Community? reportedCommunity,
  ) async {
    if (!option) {
      final result = await ref
          .read(reportControllerProvider)
          .resolveReport(widget.report.id);
      result.fold(
        (l) => showToast(false, l.message),
        (_) {
          showToast(true, 'Ignored the report!');
          Navigator.pop(context);
        },
      );
      return;
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ref.watch(preferredThemeProvider).first,
          title: const Text('Confirm Action'),
          content: Text(
            post != null
                ? 'This action will permanently delete the post. Are you sure you want to proceed?'
                : comment != null
                    ? 'This action will permanently delete the comment. Are you sure you want to proceed?'
                    : reportedUser != null
                        ? 'This action will suspend the user. Are you sure you want to proceed?'
                        : 'No action defined for this report.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: ref.watch(preferredThemeProvider).approveButtonColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                if (post != null) {
                  final result = await ref
                      .read(moderationControllerProvider.notifier)
                      .deletePost(
                          post, widget.report.message, widget.report.id);
                  await _finalizeReport(result, 'post');
                } else if (comment != null) {
                  final result = await ref
                      .read(commentControllerProvider.notifier)
                      .deleteComment(comment.id);
                  await _finalizeReport(result, 'comment');
                } else if (reportedUser != null) {
                  Logger().d("Attempting to disable user account with uid: ${reportedUser.uid}");
                  final result = await ref
                      .read(adminDashboardControllerProvider.notifier)
                      .disableUserAccount(reportedUser.uid);
                  await _finalizeReport(result, 'user suspension');
                }
              },
              child: Text(
                post != null
                    ? 'Delete Post'
                    : comment != null
                        ? 'Delete Comment'
                        : reportedUser != null
                            ? 'Suspend User'
                            : 'Confirm',
                style: TextStyle(
                  color: ref.watch(preferredThemeProvider).declineButtonColor,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }
  }

  Future<void> _finalizeReport(
      Either<Failures, void> result, String action) async {
    result.fold(
      (l) => showToast(false, l.message),
      (_) async {
        final resolveResult = await ref
            .read(reportControllerProvider)
            .resolveReport(widget.report.id);
        resolveResult.fold(
          (l) => showToast(false, l.message),
          (_) {
            Navigator.pop(context);
            showToast(true, 'Successfully completed the $action!');
          },
        );
      },
    );
  }
}

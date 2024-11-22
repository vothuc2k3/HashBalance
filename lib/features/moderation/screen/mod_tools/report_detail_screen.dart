import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/moderation/screen/post_container/report_post_container.dart';
import 'package:hash_balance/features/report/controller/report_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/conbined_models/comment_report_model.dart';
import 'package:hash_balance/models/conbined_models/post_report_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/report_model.dart';
import 'package:hash_balance/models/user_model.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  ReportDetailScreenState createState() => ReportDetailScreenState();
}

class ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  void _navigateToOtherUserScreen(
      BuildContext context, UserModel currentUser, UserModel postOwner) {
    if (currentUser.uid == postOwner.uid) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UserProfileScreen(),
        ),
      );
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OtherUserProfileScreen(targetUid: postOwner.uid),
          ));
    }
  }

  void _handleReportAction(
      bool option, Post? post, CommentModel? comment) async {
    if (!option) {
      final result = await ref
          .read(reportControllerProvider)
          .resolveReport(widget.report.id);
      result.fold((l) => showToast(false, l.message), (_) {
        showToast(true, 'Successfully ignored the report!');
        Navigator.pop(context);
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
              'This action will permanently delete the ${post != null ? 'post' : 'comment'}. Are you sure you want to proceed?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
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
                      .deletePost(post);
                  result.fold((l) => showToast(false, l.message), (_) async {
                    final result = await ref
                        .read(reportControllerProvider)
                        .resolveReport(widget.report.id);
                    result.fold(
                      (l) => showToast(false, l.message),
                      (_) {
                        Navigator.pop(context);
                        showToast(true, 'Successfully deleted the post!');
                      },
                    );
                  });
                } else if (comment != null) {
                  final result = await ref
                      .read(commentControllerProvider.notifier)
                      .deleteComment(comment.id);
                  result.fold((l) => showToast(false, l.message), (_) async {
                    final result = await ref
                        .read(reportControllerProvider)
                        .resolveReport(widget.report.id);
                    result.fold(
                      (l) => showToast(false, l.message),
                      (_) {
                        Navigator.pop(context);
                        showToast(true, 'Successfully deleted the comment!');
                      },
                    );
                  });
                }
              },
              child: Text(
                'Confirm',
                style: TextStyle(
                  color: ref.watch(preferredThemeProvider).declineButtonColor,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportData = widget.report.type == Constants.postReportType
        ? ref.watch(postReportDataProvider(widget.report))
        : ref.watch(commentReportDataProvider(widget.report));
    final currentUser = ref.read(userProvider)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: const Text('Report Details'),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _navigateToOtherUserScreen(
                              context,
                              currentUser,
                              report is PostReportModel
                                  ? report.postOwner
                                  : (report as CommentReportModel).commentOwner,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: CachedNetworkImageProvider(
                                    report is PostReportModel
                                        ? report.reporter.profileImage
                                        : (report as CommentReportModel)
                                            .reporter
                                            .profileImage,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Reporter: ${report is PostReportModel ? report.reporter.name : (report as CommentReportModel).reporter.name}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (report is PostReportModel)
                            ReportPostContainer(
                              author: report.postOwner,
                              post: report.post,
                            )
                          else if (report is CommentReportModel)
                            Text(
                              'Comment: ${report.comment.content}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Message: ${widget.report.message}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Reported at: ${formatTime(widget.report.createdAt)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor: ref
                              .watch(preferredThemeProvider)
                              .approveButtonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        onPressed: () {
                          _handleReportAction(false, null, null);
                        },
                        child: const Text(
                          'Ignore',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          backgroundColor: ref
                              .watch(preferredThemeProvider)
                              .declineButtonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        onPressed: report is PostReportModel
                            ? () {
                                _handleReportAction(
                                  true,
                                  report.post,
                                  null,
                                );
                              }
                            : () {
                                _handleReportAction(
                                  true,
                                  null,
                                  (report as CommentReportModel).comment,
                                );
                              },
                        child: Text(
                          report is PostReportModel
                              ? 'Delete post'
                              : 'Delete comment',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

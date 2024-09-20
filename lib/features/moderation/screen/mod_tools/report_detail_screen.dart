import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/moderation/controller/moderation_controller.dart';
import 'package:hash_balance/features/moderation/screen/post_container/report_post_container.dart';
import 'package:hash_balance/features/report/controller/report_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
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

  void _handleReportAction(bool option, Post? post) async {
    if (!option) {
      final result = await ref
          .read(reportControllerProvider)
          .deleteReport(widget.report.id);
      result.fold((l) => showToast(false, l.message), (_) {});
    } else {
      final result = await ref
          .read(moderationControllerProvider.notifier)
          .deletePost(post!);
      result.fold(
        (l) => showToast(false, l.message),
        (_) async {
          final result = await ref
              .read(reportControllerProvider)
              .deleteReport(widget.report.id);
          result.fold((l) => showToast(false, l.message), (_) {
            Navigator.pop(context);
            showToast(true, 'Successfully deleted the post!');
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final postReportData = ref.watch(postReportDataProvider(widget.report));
    final currentUser = ref.read(userProvider)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
      ),
      body: postReportData.when(
        data: (postReport) => Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF000000),
                Color(0xFF0D47A1),
                Color(0xFF1976D2),
              ],
            ),
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
                            postReport.postOwner,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: CachedNetworkImageProvider(
                                    postReport.reporter.profileImage),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Reporter: ${postReport.reporter.name}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Hiển thị nội dung bài đăng
                        ReportPostContainer(
                          author: postReport.postOwner,
                          post: postReport.post,
                        ),
                        const SizedBox(height: 16),

                        // Hiển thị tin nhắn báo cáo
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

                        // Hiển thị thời gian báo cáo
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
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Căn đều hai nút
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        backgroundColor: const Color(
                            0xFFB0BEC5), // Màu xám nhạt cho "Ignore"
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30), // Bo tròn nhiều hơn
                        ),
                        elevation: 5,
                      ),
                      onPressed: () {
                        _handleReportAction(false, null);
                      },
                      child: const Text(
                        'Ignore',
                        style: TextStyle(
                          color: Colors.white, // Màu chữ trắng
                          fontSize: 16, // Kích thước chữ lớn hơn một chút
                          fontWeight: FontWeight.bold, // Chữ đậm
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        backgroundColor:
                            const Color(0xFFE53935), // Màu đỏ cho "Delete post"
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30), // Bo tròn nhiều hơn
                        ),
                        elevation: 5,
                      ),
                      onPressed: () {
                        _handleReportAction(true, postReport.post);
                      },
                      child: const Text(
                        'Delete post',
                        style: TextStyle(
                          color: Colors.white, // Màu chữ trắng
                          fontSize: 16, // Kích thước chữ lớn hơn một chút
                          fontWeight: FontWeight.bold, // Chữ đậm
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

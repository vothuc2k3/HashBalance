import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/moderation/screen/post_container/report_post_container.dart';
import 'package:hash_balance/features/report/controller/report_controller.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/report_model.dart';
import 'package:hash_balance/models/user_model.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final Community community;

  const ReportScreen({
    super.key,
    required this.community,
  });

  @override
  ReportScreenState createState() => ReportScreenState();
}

class ReportScreenState extends ConsumerState<ReportScreen> {
  @override
  Widget build(BuildContext context) {
    final reportListAsync =
        ref.watch(communityReportsProvider(widget.community.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Reports'),
      ),
      body: Container(
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
        child: reportListAsync.when(
          data: (reports) {
            if (reports.isEmpty) {
              return const Center(child: Text('No reports available.'));
            }
            return ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return ReportTile(report: report);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class ReportTile extends StatelessWidget {
  final Report report;

  const ReportTile({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text('Type: ${report.type}'),
        subtitle: Text('Message: ${report.message}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'Review') {
              _reviewReport(context, report);
            } else if (value == 'Resolve') {
              _resolveReport(report);
            }
          },
          itemBuilder: (BuildContext context) {
            return ['Review', 'Resolve'].map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        ),
        onTap: () => _showReportDetails(context, report),
      ),
    );
  }

  void _showReportDetails(BuildContext context, Report report) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${report.type}'),
              Text('Reporter UID: ${report.reporterUid}'),
              if (report.reportedUid != null)
                Text('Reported User ID: ${report.reportedUid}'),
              if (report.reportedPostId != null)
                Text('Reported Post ID: ${report.reportedPostId}'),
              if (report.reportedCommentId != null)
                Text('Reported Comment ID: ${report.reportedCommentId}'),
              const SizedBox(height: 16),
              Text('Message: ${report.message}'),
              const SizedBox(height: 16),
              Text('Created at: ${report.createdAt.toDate().toString()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: const Color(0xFF42A5F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              onPressed: () {},
              child: const Text(
                'Resolve Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _reviewReport(BuildContext context, Report report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(report: report),
      ),
    );
  }

  void _resolveReport(Report report) {
    // Logic to mark the report as resolved
  }
}

class ReportDetailScreen extends ConsumerWidget {
  final Report report;

  const ReportDetailScreen({super.key, required this.report});

  void _navigateToOtherUserScreen(
      BuildContext context, UserModel currentUser, UserModel postOwner) {
    if (currentUser.uid == postOwner.uid) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(user: currentUser),
        ),
      );
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtherUserProfileScreen(targetUser: postOwner),
          ));
    }
  }

  void _handleReport()

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sử dụng postReportData để lấy dữ liệu báo cáo chi tiết
    final postReportData = ref.watch(postReportDataProvider(report));
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
                            'Message: ${report.message}',
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
                            'Reported at: ${formatTime(report.createdAt)}',
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

                // Nút giải quyết báo cáo
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    backgroundColor:
                        const Color(0xFF42A5F5), // Màu nền xanh sáng hơn
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30), // Bo tròn nhiều hơn
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {},
                  child: const Text(
                    'Resolve Report',
                    style: TextStyle(
                      color: Colors.white, // Màu chữ trắng
                      fontSize: 16, // Kích thước chữ lớn hơn một chút
                      fontWeight: FontWeight.bold, // Chữ đậm
                    ),
                  ),
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

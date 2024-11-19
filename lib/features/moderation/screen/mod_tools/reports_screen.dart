import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/report_detail_screen.dart';
import 'package:hash_balance/features/report/controller/report_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/report_model.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final Community community;

  const ReportsScreen({
    super.key,
    required this.community,
  });

  @override
  ReportsScreenState createState() => ReportsScreenState();
}

class ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: const Text('User Reports'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
        ),
        child: ref.watch(communityReportsProvider(widget.community.id)).when(
              data: (reports) {
                if (reports.isEmpty) {
                  return Center(
                    child: const Text(
                      'You have no new notifications',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ).animate().fadeIn(duration: 600.ms).moveY(
                          begin: 30,
                          end: 0,
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                  );
                }
                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return ReportTile(report: report);
                  },
                );
              },
              loading: () => const Center(
                child: Loading(),
              ),
              error: (error, stackTrace) =>
                  Center(child: Text('Error: $error')),
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

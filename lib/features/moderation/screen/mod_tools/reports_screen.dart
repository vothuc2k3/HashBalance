import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
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
        title: const Row(
          children: [
            Icon(Icons.report, color: Colors.white),
            SizedBox(width: 8),
            Text('User Reports'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {},
          ),
        ],
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
                    return ReportTile(report: report)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .moveX(begin: -30, end: 0, curve: Curves.easeOut);
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

class ReportTile extends ConsumerWidget {
  final Report report;

  const ReportTile({super.key, required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusColor = report.isResolved ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: ref.watch(preferredThemeProvider).third,
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            report.isResolved ? Icons.check : Icons.warning,
            color: Colors.white,
          ),
        ),
        title: Text(
          'Type: ${report.type == Constants.postReportType ? 'Post Report' : 'Comment Report'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Message: ${report.message}'),
            const SizedBox(height: 4),
            Text(
              report.isResolved ? 'Resolved' : 'Pending',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: report.isResolved
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'Review') {
                    _showReportDetails(context, report);
                  } else if (value == 'Resolve') {
                    _resolveReport(report, ref);
                  }
                },
                itemBuilder: (context) {
                  return ['Review', 'Resolve'].map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(choice),
                    );
                  }).toList();
                },
              ),
        onTap: report.isResolved
            ? () {}
            : () => _showReportDetails(context, report),
      ),
    );
  }

  void _showReportDetails(BuildContext context, Report report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(
          report: report,
        ),
      ),
    );
  }

  void _resolveReport(Report report, WidgetRef ref) async {
    final result =
        await ref.read(reportControllerProvider).resolveReport(report.id);
    result.fold(
      (l) => showToast(false, l.message),
      (_) {
        showToast(true, 'Successfully resolved the report!');
      },
    );
  }
}

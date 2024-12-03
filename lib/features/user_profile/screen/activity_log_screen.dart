import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/activity_log/controller/activity_log_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hash_balance/models/activity_log_model.dart';

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  List<ActivityLogModel> _activityLogs = [];

  void _clearActivityLogs() async {
    showCustomAlertDialog(
      context: context,
      title: 'Clear Activity Logs',
      content: 'Are you sure you want to clear all activity logs?',
      backgroundColor: ref.watch(preferredThemeProvider).second,
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.greenAccent,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
          onPressed: () async {
            Navigator.of(context).pop();
            final result = await ref
                .read(activityLogControllerProvider.notifier)
                .clearActivityLogs();
            result.fold((l) => showToast(false, l.message), (r) {
              showToast(true, 'Activity logs cleared');
              setState(() {
                _activityLogs = [];
              });
            });
          },
          child: const Text('Clear'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Activities'),
        backgroundColor: ref.watch(preferredThemeProvider).first,
        actions: [
          IconButton(
            onPressed: _clearActivityLogs,
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).second,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ref.watch(activityLogStreamProvider).when(
                data: (activityLogs) {
                  _activityLogs = activityLogs;
                  if (_activityLogs.isEmpty) {
                    return Center(
                      child: const Text(
                        'You have no logs...',
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
                    itemCount: _activityLogs.length,
                    itemBuilder: (context, index) {
                      final behavior = _activityLogs[index];
                      return _buildBehaviorCard(behavior).animate().fadeIn();
                    },
                  );
                },
                error: (error, stack) =>
                    Text(error.toString()).animate().fadeIn(),
                loading: () =>
                    const Center(child: Loading()).animate().fadeIn(),
              ),
        ),
      ),
    );
  }

  Widget _buildBehaviorCard(ActivityLogModel activityLog) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: ref.watch(preferredThemeProvider).third,
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blueAccent,
          child: Icon(
            _getIconByType(activityLog.activityType),
            color: Colors.white,
            size: 28,
          ),
        ),
        title: Text(
          activityLog.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activityLog.message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              formatTime(activityLog.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    ).animate().fadeIn().moveY(begin: 20, end: 0, curve: Curves.easeOutBack);
  }

  IconData _getIconByType(String type) {
    switch (type) {
      case Constants.activityLogTypeUpvote:
        return Icons.thumb_up;
      case Constants.activityLogTypeDownvote:
        return Icons.thumb_down;
      case Constants.activityLogTypeComment:
        return Icons.comment;
      case Constants.activityLogTypeCreatePost:
        return Icons.post_add;
      default:
        return Icons.circle;
    }
  }
}

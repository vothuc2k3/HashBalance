import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Activities'),
        backgroundColor: ref.watch(preferredThemeProvider).first,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).second,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ref.watch(activityLogStreamProvider).when(
                data: (activityLogs) {
                  if (activityLogs.isEmpty) {
                    return const Center(
                      child: Text('No activities yet.'),
                    ).animate().fadeIn();
                  }
                  return ListView.builder(
                    itemCount: activityLogs.length,
                    itemBuilder: (context, index) {
                      final behavior = activityLogs[index];
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
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: ref.watch(preferredThemeProvider).third,
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.blueAccent,
          child: Icon(
            _getIconByType(activityLog.activityType),
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          activityLog.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          '${activityLog.message}\n${formatTime(activityLog.createdAt)}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        isThreeLine: true,
      ),
    ).animate().fadeIn().moveY(begin: 20, end: 0, curve: Curves.easeOutBack);
  }

  IconData _getIconByType(String type) {
    switch (type) {
      case 'like':
        return Icons.thumb_up;
      case 'comment':
        return Icons.comment;
      case 'share':
        return Icons.share;
      case 'favorite':
        return Icons.star;
      case 'join':
        return Icons.group_add;
      default:
        return Icons
            .circle; // Biểu tượng mặc định nếu không khớp với các loại trên
    }
  }
}

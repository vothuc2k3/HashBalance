import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return ref.watch(getNotifsProvider(user!.uid)).when(
          data: (notifs) {
            if (notifs == null || notifs.isEmpty) {
              return Scaffold(
                body: Center(
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
                ),
              );
            }
            return Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  return ListView.builder(
                    itemCount: notifs.length,
                    itemBuilder: (context, index) {
                      var notif = notifs[index];
                      var timeString = formatTime(notif.createdAt);
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: notif.read
                              ? Colors.grey[850]
                              : Colors.blueGrey[700],
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            notif.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif.message,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                timeString,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: notif.read
                              ? null
                              : const Icon(Icons.new_releases,
                                  color: Colors.red),
                          onTap: () {},
                        ).animate().fadeIn(duration: 600.ms).moveY(
                            begin: 30,
                            end: 0,
                            duration: 600.ms,
                            curve: Curves.easeOutBack),
                      );
                    },
                  );
                },
              ),
            );
          },
          error: (Object error, StackTrace stackTrace) => ErrorText(
            error: error.toString(),
          ),
          loading: () => const Loading(),
        );
  }
}

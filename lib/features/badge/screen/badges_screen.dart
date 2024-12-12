import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/badge/controller/badge_controller.dart';
import 'package:hash_balance/features/badge/screen/create_badge_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';

class BadgesScreen extends ConsumerStatefulWidget {
  final bool isAdmin;

  const BadgesScreen({
    super.key,
    required this.isAdmin,
  });

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  Future<void> _onRefresh() async {
    ref.invalidate(badgesProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              backgroundColor: ref.watch(preferredThemeProvider).second,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateBadgeScreen(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: const Text("Badges"),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        color: ref.watch(preferredThemeProvider).first,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ref.watch(badgesProvider).when(
            data: (badges) {
              if (badges.isEmpty) {
                return Center(
                  child: const Text(
                    "No badges found...",
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
              badges.sort((a, b) => a.threshold.compareTo(b.threshold));
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  return ref.watch(hasBadgeProvider(badge.id)).when(
                    data: (hasBadge) {
                      return Card(
                        color: hasBadge
                            ? Colors.green[800]
                            : ref.watch(preferredThemeProvider).second,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: CachedNetworkImage(
                                  imageUrl: badge.imageUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                badge.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasBadge ? "You have this badge!" : badge.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms).scale(
                            duration: 300.ms,
                            curve: Curves.easeOutBack,
                          );
                    },
                    error: (error, stackTrace) {
                      return Center(
                        child: Text(
                          "Error: $error",
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    },
                    loading: () {
                      return const Center(
                        child: Loading(),
                      );
                    },
                  );
                },
              );
            },
            error: (Object error, StackTrace stackTrace) {
              return Center(
                child: Text(
                  "Error: $error",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            },
            loading: () {
              return const Center(
                child: Loading(),
              );
            },
          ),
        ),
      ),
    );
  }
}

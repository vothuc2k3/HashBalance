import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                        builder: (context) => const CreateBadgeScreen()));
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
              return ListView.builder(
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  return Text(badges[index].name);
                },
              );
            },
            error: (Object error, StackTrace stackTrace) {
              return Center(child: Text("Error: $error"));
            },
            loading: () {
              return const Center(child: Text("Loading..."));
            },
          ),
        ),
      ),
    );
  }
}

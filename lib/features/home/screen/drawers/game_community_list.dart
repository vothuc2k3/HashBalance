import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GameCommunityListDrawer extends ConsumerWidget {
  const GameCommunityListDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: const Text('Create your new Community'),
              leading: const Icon(
                Icons.add,
              ),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

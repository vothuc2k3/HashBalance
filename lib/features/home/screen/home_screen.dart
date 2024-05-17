import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/home/delegates/search_community_delegate.dart';
import '../../authentication/repository/auth_repository.dart';
import 'drawers/gaming_community_list_drawer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void displayDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: false,
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              displayDrawer(context);
            },
          );
        }),
        actions: [
          IconButton(
            onPressed: () {
              showSearch(
                context: context,
                delegate: SearchCommunityDelegate(ref),
              );
            },
            icon: const Icon(
              Icons.search,
            ),
          ),
          IconButton(
            icon: CircleAvatar(
              backgroundImage: NetworkImage(user!.profileImage),
            ),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const GameCommunityListDrawer(),
    );
  }
}

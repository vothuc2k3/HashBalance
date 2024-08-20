import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/home/delegates/search_delegate.dart';
import 'package:hash_balance/features/home/screen/drawers/community_list_drawer.dart';
import 'package:hash_balance/features/home/screen/drawers/user_profile_drawer.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  int _page = 0;
  late PageController _pageController;

  @override
  void initState() {
    _pageController = PageController();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await requestPushPermissions();
    });
  }

  Future<void> requestPushPermissions() async {
    await ref.watch(firebaseMessagingProvider).requestPermission();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void displayCommunityListDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  void displayUserProfileDrawer(BuildContext context) {
    Scaffold.of(context).openEndDrawer();
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            Constants.titles[_page],
            key: ValueKey(_page),
          ),
        ),
        centerTitle: false,
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => displayCommunityListDrawer(context),
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
          Builder(
            builder: (context) {
              return IconButton(
                icon: CircleAvatar(
                  backgroundImage:
                      CachedNetworkImageProvider(user!.profileImage),
                ),
                onPressed: () => displayUserProfileDrawer(context),
              );
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: onPageChanged,
        children: Constants.tabWidgets,
      ),
      drawer: const CommunityListDrawer(),
      endDrawer: UserProfileDrawer(homeScreenContext: context),
      bottomNavigationBar: CupertinoTabBar(
        backgroundColor: Colors.black87,
        activeColor: Colors.teal,
        inactiveColor: Colors.white70,
        iconSize: 28.0,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_search_outlined),
            label: 'Communities',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_outlined),
            label: 'Create',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: ref.watch(getNotifsProvider(user!.uid)).when(
                data: (notifs) {
                  if (notifs == null || notifs.isEmpty) {
                    return const Icon(Icons.notification_add_outlined);
                  }
                  int unreadCount = 0;
                  for (var notif in notifs) {
                    if (notif.isRead == false) {
                      unreadCount++;
                    }
                  }
                  return unreadCount == 0
                      ? const Icon(Icons.notification_add_outlined)
                      : Badge(
                          label: Text(
                            '$unreadCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                          isLabelVisible: true,
                          child: const Icon(Icons.notification_add_outlined),
                        );
                },
                error: (Object error, StackTrace stackTrace) =>
                    ErrorText(error: error.toString()),
                loading: () => const Loading()),
            label: 'Inbox',
          ),
        ],
        onTap: onTabTapped,
        currentIndex: _page,
      ),
    );
  }
}

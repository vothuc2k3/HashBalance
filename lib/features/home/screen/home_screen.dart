import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/home/delegates/search_delegate.dart';
import 'package:hash_balance/features/home/screen/drawers/community_list_drawer.dart';
import 'package:hash_balance/features/home/screen/drawers/user_profile_drawer.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';
import 'package:hash_balance/models/call_model.dart';
import 'package:hash_balance/models/notification_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
  });

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

  Stream<Call?> listenToIncomingCalls(String userId) {
    return FirebaseFirestore.instance
        .collection(FirebaseConstants.callCollection)
        .where('receiverUid', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      } else {
        return Call.fromMap(snapshot.docs.first.data());
      }
    });
  }

  void _handleIncomingCall(Call call) {}

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000), // Màu đen ở trên
              Color(0xFF0D47A1), // Màu xanh ở giữa
              Color(0xFF1976D2), // Màu xanh đậm ở dưới
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent, // Để không ghi đè gradient
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
              StreamBuilder<Call?>(
                stream: listenToIncomingCalls(user!.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Icon(Icons.error, color: Colors.red);
                  } else if (snapshot.hasData && snapshot.data != null) {
                    final call = snapshot.data!;
                    return IconButton(
                      icon: const Icon(Icons.call, color: Colors.green),
                      onPressed: () {
                        _handleIncomingCall(call);
                      },
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),

              // Other actions
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

              ref.watch(getNotifsProvider(user.uid)).whenOrNull(
                    data: (notifs) {
                      if (notifs == null || notifs.isEmpty) {
                        return const SizedBox.shrink();
                      } else {
                        return _buildNotificationMenu(notifs);
                      }
                    },
                  ) ??
                  _buildNotificationMenu([]),

              //MARK: - PROFILE
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: CircleAvatar(
                      backgroundImage:
                          CachedNetworkImageProvider(user.profileImage),
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
                icon: ref.watch(getNotifsProvider(user.uid)).whenOrNull(
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
                                child:
                                    const Icon(Icons.notification_add_outlined),
                              );
                      },
                    ) ??
                    const Icon(Icons.notification_add_outlined),
                label: 'Inbox',
              ),
            ],
            onTap: onTabTapped,
            currentIndex: _page,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationMenu(List<NotificationModel> notifs) {
    return Stack(
      children: [
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.notifications,
            color: Colors.white,
          ),
          onSelected: (value) {},
          itemBuilder: (BuildContext context) {
            if (notifs.isEmpty) {
              return [
                const PopupMenuItem<String>(
                  value: '',
                  child: ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text('No notifications'),
                  ),
                )
              ];
            }
            return notifs.map((NotificationModel notification) {
              return PopupMenuItem<String>(
                value: notification.title,
                child: ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(notification.message),
                ),
              );
            }).toList();
          },
        ),
        Positioned(
          right: 11,
          top: 11,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                notifs.isNotEmpty
                    ? notifs.length.toString()
                    : '', // Hiển thị số lượng thông báo
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

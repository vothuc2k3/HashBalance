import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/call/controller/call_controller.dart';
import 'package:hash_balance/features/call/screen/incoming_call_screen.dart';
import 'package:hash_balance/features/home/delegates/search_delegate.dart';
import 'package:hash_balance/features/home/screen/drawers/community_list_drawer.dart';
import 'package:hash_balance/features/home/screen/drawers/user_profile_drawer.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';
import 'package:hash_balance/features/theme/controller/theme_controller.dart';
import 'package:hash_balance/models/conbined_models/call_data_model.dart';
import 'package:hash_balance/models/notification_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  int _page = 0;
  late PageController _pageController;
  bool _isIncomingCallScreenOpen = false;

  Future<void> _requestPushPermissions() async {
    await ref.watch(firebaseMessagingProvider).requestPermission();
  }

  void _displayCommunityListDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }

  void _displayUserProfileDrawer(BuildContext context) {
    Scaffold.of(context).openEndDrawer();
  }

  void _onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void onTabTapped(int index) {
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _navigateToIncomingCallScreen(CallDataModel callData) {
    if (!_isIncomingCallScreenOpen) {
      _isIncomingCallScreenOpen = true;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IncomingCallScreen(callData: callData),
        ),
      ).then((_) {
        _isIncomingCallScreenOpen = false;
      });
    }
  }

  @override
  void initState() {
    _pageController = PageController();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        await _requestPushPermissions();
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CallDataModel?>>(
      listenToIncomingCallsProvider,
      (previous, next) {
        next.whenOrNull(
          data: (callDataModel) {
            if (callDataModel != null &&
                callDataModel.call.status == Constants.callStatusDialling) {
              _navigateToIncomingCallScreen(callDataModel);
            }
          },
        );
      },
    );
    final user = ref.watch(userProvider);

    GlobalAnimationController.initialize(this);

    return Scaffold(
      body: Container(
        color: ref.watch(preferredThemeProvider),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: ref.watch(preferredThemeProvider),
            title: AnimatedBuilder(
              animation: GlobalAnimationController.animationController!,
              builder: (context, child) {
                return Transform.scale(
                  scale: GlobalAnimationController.animationController!.value,
                  child: child,
                );
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  Constants.titles[_page],
                  key: ValueKey(_page),
                ),
              ),
            ),
            centerTitle: false,
            leading: Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _displayCommunityListDrawer(context),
                );
              },
            ),
            actions: [
              //MARK: - SEARCH
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

              //MARK: - NOTIFICATIONS
              if (user != null)
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
              if (user != null)
                Builder(
                  builder: (context) {
                    return IconButton(
                      icon: CircleAvatar(
                        backgroundImage:
                            CachedNetworkImageProvider(user.profileImage),
                      ),
                      onPressed: () => _displayUserProfileDrawer(context),
                    );
                  },
                ),
            ],
          ),
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: Constants.tabWidgets,
          ),
          drawer: const CommunityListDrawer(),
          endDrawer: UserProfileDrawer(homeScreenContext: context),
          bottomNavigationBar: CupertinoTabBar(
            backgroundColor: const Color(0xff181C30),
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
              if (user != null)
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
                                  child: const Icon(
                                      Icons.notification_add_outlined),
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
              notifs.isNotEmpty ? notifs.length.toString() : '',
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

class GlobalAnimationController {
  static AnimationController? animationController;

  static void initialize(TickerProvider vsync) {
    animationController ??= AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 2),
    );
  }

  static void start() {
    animationController?.forward();
  }

  static void dispose() {
    animationController?.dispose();
    animationController = null;
  }
}

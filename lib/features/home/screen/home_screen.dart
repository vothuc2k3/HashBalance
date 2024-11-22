import 'package:cached_network_image/cached_network_image.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/call/controller/call_controller.dart';
import 'package:hash_balance/features/call/screen/incoming_call_screen.dart';
import 'package:hash_balance/features/home/screen/drawers/community_list_drawer.dart';
import 'package:hash_balance/features/home/screen/drawers/user_profile_drawer.dart';
import 'package:hash_balance/features/home/screen/search_screen.dart';
import 'package:hash_balance/features/notification/controller/notification_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_devices/controller/user_device_controller.dart';
import 'package:hash_balance/models/conbined_models/call_data_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  int _page = 0;
  late PageController _pageController;
  bool _isIncomingCallScreenOpen = false;

  Future<void> _updateUserDeviceToken() async {
    final token = await ref.read(firebaseMessagingProvider).getToken();
    final uid = ref.read(userProvider)!.uid;
    ref
        .read(userDeviceControllerProvider)
        .addUserDevice(uid: uid, deviceToken: token ?? '');
  }

  Future<void> _requestPushPermissions() async {
    final settings =
        await ref.read(firebaseMessagingProvider).requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _updateUserDeviceToken();
    }
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

  _navigateToSearchScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchSuggestionsScreen(),
      ),
    );
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

    return Scaffold(
      body: Container(
        color: ref.watch(preferredThemeProvider).first,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: ref.watch(preferredThemeProvider).third,
            title: Text(
              Constants.titles[_page],
              key: ValueKey(_page),
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
                onPressed: () => _navigateToSearchScreen(),
                icon: const Icon(
                  Icons.search,
                ),
              ),

              //MARK: - NOTIFICATIONS
              // if (user != null)
              //   ref.watch(getNotifsProvider(user.uid)).whenOrNull(
              //         data: (notifs) {
              //           if (notifs == null || notifs.isEmpty) {
              //             return const SizedBox.shrink();
              //           } else {
              //             return _buildNotificationMenu(notifs);
              //           }
              //         },
              //       ) ??
              //       _buildNotificationMenu([]),

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
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: Constants.tabWidgets,
          ),
          drawer: const CommunityListDrawer(),
          endDrawer: const UserProfileDrawer(),
          bottomNavigationBar: CurvedNavigationBar(
            index: _page,
            height: 60.0,
            items: [
              const Icon(Icons.home, size: 30, color: Colors.white),
              const Icon(Icons.person_search_outlined,
                  size: 30, color: Colors.white),
              const Icon(Icons.add_circle, size: 30, color: Colors.white),
              const Icon(Icons.message_outlined, size: 30, color: Colors.white),
              if (user != null)
                ref.watch(getUnreadNotifCountProvider(user.uid)).whenOrNull(
                      data: (unreadCount) {
                        if (unreadCount == 0) {
                          return const Icon(
                            Icons.notification_add_outlined,
                            size: 30,
                            color: Colors.white,
                          );
                        }
                        return Badge(
                          label: Text(
                            '$unreadCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                          isLabelVisible: true,
                          child: const Icon(
                            Icons.notification_add_outlined,
                            size: 30,
                          ),
                        );
                      },
                    ) ??
                    const Icon(Icons.notification_add_outlined,
                        size: 30, color: Colors.white),
            ],
            color: ref.watch(preferredThemeProvider).first,
            backgroundColor: ref.watch(preferredThemeProvider).second,
            buttonBackgroundColor: ref.watch(preferredThemeProvider).third,
            animationCurve: Curves.easeInOut,
            animationDuration: const Duration(milliseconds: 300),
            onTap: onTabTapped,
            letIndexChange: (index) => true,
          ),
        ),
      ),
    );
  }
}

// Widget _buildNotificationMenu(List<NotificationModel> notifs) {
//   return Stack(
//     children: [
//       PopupMenuButton<String>(
//         icon: const Icon(
//           Icons.notifications,
//           color: Colors.white,
//         ),
//         onSelected: (value) {},
//         itemBuilder: (BuildContext context) {
//           if (notifs.isEmpty) {
//             return [
//               const PopupMenuItem<String>(
//                 value: '',
//                 child: ListTile(
//                   leading: Icon(Icons.notifications),
//                   title: Text('No notifications'),
//                 ),
//               )
//             ];
//           }
//           return notifs.where((NotificationModel notification) {
//             return notification.isRead == false;
//           }).map((NotificationModel notification) {
//             return PopupMenuItem<String>(
//               value: notification.title,
//               child: ListTile(
//                 leading: const Icon(Icons.notifications),
//                 title: Text(notification.message),
//               ),
//             );
//           }).toList();
//         },
//       ),
//       Positioned(
//         right: 11,
//         top: 11,
//         child: IgnorePointer(
//           child: Container(
//             padding: const EdgeInsets.all(1),
//             decoration: BoxDecoration(
//               color: Colors.red,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             constraints: const BoxConstraints(
//               minWidth: 16,
//               minHeight: 16,
//             ),
//             child: Text(
//               notifs.isNotEmpty ? notifs.length.toString() : '',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ),
//       ),
//     ],
//   );
// }

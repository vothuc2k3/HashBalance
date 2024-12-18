import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/widget/followers_widget.dart';
import 'package:hash_balance/features/user_profile/screen/widget/following_widget.dart';

class UserFollowersScreen extends ConsumerStatefulWidget {
  const UserFollowersScreen({
    super.key,
  });

  @override
  ConsumerState<UserFollowersScreen> createState() =>
      _UserFollowersScreenState();
}

class _UserFollowersScreenState extends ConsumerState<UserFollowersScreen> {
  final PageController _pageController = PageController();
  int _page = 0;
  final _titles = const ['Followers', 'Following'];

  void _onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).third,
        title: Text(
          _titles[_page],
          key: ValueKey(_page),
        ),
        centerTitle: false,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          FollowersWidget(),
          FollowingWidget(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _page,
        height: 60.0,
        items: const [
          Icon(Icons.people, size: 30, color: Colors.white),
          Icon(Icons.person_add_alt_1, size: 30, color: Colors.white),
        ],
        color: ref.watch(preferredThemeProvider).first,
        backgroundColor: ref.watch(preferredThemeProvider).second,
        buttonBackgroundColor: ref.watch(preferredThemeProvider).third,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: _onTabTapped,
        letIndexChange: (index) => true,
      ),
    );
  }
}

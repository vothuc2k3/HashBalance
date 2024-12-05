import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/post/screen/widgets/create_poll_widget.dart';
import 'package:hash_balance/features/post/screen/widgets/create_post_widget.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  final Community? chosenCommunity;
  final bool? isFromCommunityScreen;

  const CreatePostScreen({
    super.key,
    this.chosenCommunity,
    this.isFromCommunityScreen,
  });

  @override
  CreatePostScreenState createState() => CreatePostScreenState();
}

class CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  int _page = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: const Text(
          'Create Post',
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          CreatePostWidget(),
          CreatePollWidget(),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _page,
        height: 60.0,
        items: const [
          Icon(Icons.post_add, size: 20, color: Colors.white),
          Icon(Icons.poll_outlined, size: 20, color: Colors.white),
        ],
        color: ref.watch(preferredThemeProvider).first,
        backgroundColor: ref.watch(preferredThemeProvider).second,
        buttonBackgroundColor: ref.watch(preferredThemeProvider).third,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: onTabTapped,
        letIndexChange: (index) => true,
      ),
    );
  }

  void onTabTapped(int index) {
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }
}

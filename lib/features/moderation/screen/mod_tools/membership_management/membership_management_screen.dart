import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/membership_management/member_list_screen.dart';
import 'package:hash_balance/features/moderation/screen/mod_tools/membership_management/suspended_users_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/community_model.dart';

class MembershipManagementScreen extends ConsumerStatefulWidget {
  final Community community;

  const MembershipManagementScreen({
    super.key,
    required this.community,
  });

  @override
  ConsumerState<MembershipManagementScreen> createState() =>
      _MembershipManagementScreenState();
}

class _MembershipManagementScreenState
    extends ConsumerState<MembershipManagementScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      MemberListScreen(community: widget.community),
      SuspendedUsersScreen(community: widget.community),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: const Text('Membership Management'),
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: ref.watch(preferredThemeProvider).second,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Members List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.block),
            label: 'Suspended Users',
          ),
        ],
      ),
    );
  }
}

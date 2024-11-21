import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/authentication/screen/auth_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_devices/controller/user_device_controller.dart';
import 'package:hash_balance/features/user_profile/controller/user_controller.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<SettingScreen> createState() {
    return SettingScreenState();
  }
}

class SettingScreenState extends ConsumerState<SettingScreen> {
  bool _isNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  void _showPrivacySettings() {
    final currentUser = ref.read(userProvider)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ref.watch(preferredThemeProvider).first,
        title: const Text('Privacy Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Restricted'),
              tileColor: currentUser.isRestricted ? Colors.grey[300] : null,
              onTap: () async {
                Navigator.of(context).pop();
                UserModel newUser = currentUser.copyWith(isRestricted: true);
                final result = await ref
                    .read(userControllerProvider.notifier)
                    .updateUserPrivacy(newUser);
                result.fold(
                  (l) => showToast(false, l.message),
                  (_) => showToast(true, 'Privacy settings updated'),
                );
              },
            ),
            ListTile(
              title: const Text('Open'),
              tileColor: !currentUser.isRestricted ? Colors.grey[300] : null,
              onTap: () async {
                Navigator.of(context).pop();
                UserModel newUser = currentUser.copyWith(isRestricted: false);
                final result = await ref
                    .read(userControllerProvider.notifier)
                    .updateUserPrivacy(newUser);
                result.fold(
                  (l) => showToast(false, l.message),
                  (_) => showToast(true, 'Privacy settings updated'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _loadNotificationSetting() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.getNotificationSettings();
    setState(() {
      _isNotificationsEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized;
    });
  }

  void _toggleNotifications(bool value) async {
    setState(() {
      _isNotificationsEnabled = value;
    });
    final currentUser = ref.read(userProvider)!;
    if (value) {
      final permission = await FirebaseMessaging.instance.requestPermission();
      if (permission.authorizationStatus == AuthorizationStatus.authorized) {
        final deviceToken = await FirebaseMessaging.instance.getToken();
        if (deviceToken != null) {
          await ref.read(userDeviceControllerProvider).addUserDevice(
                uid: currentUser.uid,
                deviceToken: deviceToken,
              );
          showToast(true, 'Notifications Enabled');
        } else {
          showToast(false, 'Failed to get device token.');
          setState(() {
            _isNotificationsEnabled = false;
          });
        }
      } else {
        showToast(false, 'Notification permission denied.');
        setState(() {
          _isNotificationsEnabled = false;
        });
      }
    } else {
      final deviceToken = await FirebaseMessaging.instance.getToken();
      if (deviceToken != null) {
        await ref.read(userDeviceControllerProvider).removeUserDeviceToken(
              uid: currentUser.uid,
              deviceToken: deviceToken,
            );
      }
      showToast(true, 'Notifications Disabled');
    }
  }

  void _changeTheme() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose a Theme Color'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purple,
                ),
                title: const Text('Purple Theme'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                ),
                title: const Text('Blue Theme'),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _signOut(String uid) async {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
    await ref.watch(authControllerProvider.notifier).signOut(uid);
  }

  void _testButton() async {}

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
    final currentUser = ref.watch(userProvider)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ref.watch(preferredThemeProvider).second,
        title: const Text(
          'Setting',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
        ),
        child: Column(
          children: [
            ListTile(
              title: Text(
                currentUser.isRestricted
                    ? 'Privacy: Restricted'
                    : 'Privacy: Open',
                style: const TextStyle(
                  color: Pallete.whiteColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: const Icon(Icons.privacy_tip),
              onTap: () => _showPrivacySettings(),
            ),
            SwitchListTile(
              title: const Text(
                'Enable Push Notifications',
                style: TextStyle(
                  color: Pallete.whiteColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              value: _isNotificationsEnabled,
              onChanged: _toggleNotifications,
              secondary: const Icon(Icons.notifications),
            ),
            ListTile(
              leading: const Icon(
                Icons.color_lens,
                color: Pallete.whiteColor,
              ),
              title: const Text(
                'Change Theme',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _changeTheme,
            ),
            ListTile(
              leading: isLoading
                  ? const Loading()
                  : const Icon(
                      Icons.logout,
                      color: Pallete.whiteColor,
                    ),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => _signOut(currentUser.uid),
            ),
            ListTile(
              leading: Icon(
                Icons.logout,
                color: Pallete.redColor,
              ),
              title: const Text(
                'TEST BUTTON',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _testButton,
            ),
          ],
        ),
      ),
    );
  }
}

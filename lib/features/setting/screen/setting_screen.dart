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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.blue),
            SizedBox(width: 8),
            Text('Privacy Settings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              value: true,
              groupValue: currentUser.isRestricted,
              activeColor: Colors.blue,
              title: const Text('Restricted'),
              subtitle: const Text(
                  'Only approved followers can see your posts and profile.'),
              onChanged: (value) async {
                Navigator.of(context).pop();
                UserModel newUser = currentUser.copyWith(isRestricted: value!);
                final result = await ref
                    .read(userControllerProvider.notifier)
                    .updateUserPrivacy(newUser);
                result.fold(
                  (l) => showToast(false, l.message),
                  (_) => showToast(true, 'Privacy settings updated'),
                );
              },
            ),
            const Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey), // Dòng kẻ phân cách
            RadioListTile<bool>(
              value: false,
              groupValue: currentUser.isRestricted,
              activeColor: Colors.blue,
              title: const Text('Open'),
              subtitle: const Text(
                  'Anyone can see your posts and profile without approval.'),
              onChanged: (value) async {
                Navigator.of(context).pop();
                UserModel newUser = currentUser.copyWith(isRestricted: value!);
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

  void _navigateToSupport() {
    // TODO: Implement support and feedback navigation
  }

  void _signOut(String uid) async {
    await ref.watch(authControllerProvider.notifier).signOut(uid);
    // ignore: use_build_context_synchronously
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false);
  }

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
              leading: const Icon(
                Icons.help,
                color: Pallete.whiteColor,
              ),
              title: const Text(
                'Support & Feedback',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _navigateToSupport,
            ),
            const Spacer(),
            ListTile(
              leading: isLoading
                  ? const Loading()
                  : Icon(
                      Icons.logout,
                      color:
                          ref.watch(preferredThemeProvider).declineButtonColor,
                    ),
              title: Text(
                'Sign Out',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        ref.watch(preferredThemeProvider).declineButtonColor),
              ),
              onTap: () => _signOut(currentUser.uid),
            ),
          ],
        ),
      ),
    );
  }
}

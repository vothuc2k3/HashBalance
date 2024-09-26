import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/splash/splash_screen.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/authentication/screen/auth_screen.dart';
import 'package:hash_balance/features/newsfeed/controller/newsfeed_controller.dart';
import 'package:hash_balance/features/newsfeed/screen/containers/newsfeed_poll_container.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:logger/logger.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<SettingScreen> createState() {
    return SettingScreenState();
  }
}

class SettingScreenState extends ConsumerState<SettingScreen> {
  void _changeTheme() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  ref.read(preferredThemeProvider.notifier).setTheme(
                        const ThemeColors(
                          first: Color(0xFF6A0DAD),
                          second: Color(0xFF4A0B7E),
                          third: Color(0xFF3A0A5D),
                          approveButtonColor: Colors.purple,
                          declineButtonColor: Colors.red,
                          transparentButtonColor: Colors.transparent,
                        ),
                      );
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                ),
                title: const Text('Blue Theme'),
                onTap: () {
                  ref.read(preferredThemeProvider.notifier).setTheme(
                        const ThemeColors(
                          first: Color(0xFF1E90FF),
                          second: Color(0xFF1A73E8),
                          third: Color(0xFF155FA0),
                          approveButtonColor: Colors.blue,
                          declineButtonColor: Colors.red,
                          transparentButtonColor: Colors.transparent,
                        ),
                      );
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _signOut(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      ),
    );
    await ref.watch(authControllerProvider.notifier).signOut(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),
      (route) => false,
    );
  }

  void _testButton() async {}

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);
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
              onTap: () => _signOut(context),
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
            ref.watch(pollProvider(ref.read(userProvider)!.uid)).when(
                  data: (data) {
                    if (data.isEmpty) {
                      Logger().d('No polls available');
                      return const SizedBox.shrink();
                    }
                    Logger().d('Polls available: ${data.length}');
                    return ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        return PollContainer(
                          author: data[index].author,
                          poll: data[index].poll,
                          options: data[index].options,
                          community: data[index].community,
                        );
                      },
                    );
                  },
                  error: (error, stackTrace) =>
                      ErrorText(error: error.toString()),
                  loading: () => const Loading(),
                ),
          ],
        ),
      ),
    );
  }
}

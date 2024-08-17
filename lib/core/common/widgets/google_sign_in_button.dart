import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/theme/pallette.dart';

class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({
    super.key,
  }) ;


  void signInWithGoogle(WidgetRef ref) async {
    final result =
        await ref.watch(authControllerProvider.notifier).signInWithGoogle();
    result.fold((l) {
      showToast(false, l.message);
    }, (r) {});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => signInWithGoogle(ref),
      icon: Image.asset(
        Constants.googleLogoPath,
        width: 35,
      ),
      label: const Text(
        'Join with Google',
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Pallete.greyColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

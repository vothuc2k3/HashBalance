import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/widgets/google_sign_in_button.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_in_screen.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_up_screen.dart';
import 'package:hash_balance/features/authentication/screen/forgot_password_screen.dart';
import 'package:hash_balance/theme/pallette.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  void navigateToEmailSignUpScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailSignUpScreen(),
      ),
    );
  }

  void navigateToEmailSignInScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailSignInScreen(),
      ),
    );
  }

  void navigateToForgotPasswordScreen(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ForgotPasswordScreen(),
        ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authControllerProvider);
    final screenHeight =
        MediaQuery.of(context).size.height; // Lấy chiều cao màn hình

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          Constants.logoPath,
          height: 45,
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Skip',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        height: screenHeight, // Đặt chiều cao toàn màn hình
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000),
              Color(0xFF0D47A1),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: isLoading
            ? const Loading()
            : SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight, // Đảm bảo chiều cao tối thiểu
                  ),
                  child: IntrinsicHeight(
                    // Sử dụng IntrinsicHeight để phù hợp với các widget bên trong
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween, // Căn giữa nội dung
                      children: [
                        const SizedBox(height: 30),
                        const Text(
                          'Let\'s join the communities!',
                          style: TextStyle(
                            fontSize: 24,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            Constants.signinEmotePath,
                            height: 400,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30),
                          child: GoogleSignInButton(),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              navigateToEmailSignUpScreen(context);
                            },
                            icon: Image.asset(
                              Constants.emailLogoPath,
                              width: 35,
                            ),
                            label: const Text(
                              'Join with Email',
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
                          ),
                        ),
                        const Spacer(), // Thêm khoảng trống để đẩy các thành phần cuối xuống đáy màn hình
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Already have an account? ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        color: Colors
                                            .white, // Giữ màu chữ của câu hỏi là trắng
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        navigateToEmailSignInScreen(context);
                                      },
                                      child: const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 16, // Giữ kích thước chữ
                                          fontWeight: FontWeight
                                              .bold, // Đặt chữ in đậm để nổi bật hơn
                                          color: Colors
                                              .white, // Thay đổi màu chữ thành trắng để phù hợp với nền
                                          shadows: [
                                            Shadow(
                                              offset: Offset(0, 1),
                                              blurRadius: 2.0,
                                              color: Colors
                                                  .black45, // Thêm bóng nhẹ để nổi bật hơn
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                    navigateToEmailSignInScreen(context);
                                  },
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 1),
                                          blurRadius: 2.0,
                                          color: Colors.black45,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

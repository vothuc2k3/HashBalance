import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/common/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_up_screen.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/theme/pallette.dart';

class EmailSignInScreen extends ConsumerStatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  EmailSignInScreenState createState() => EmailSignInScreenState();
}

class EmailSignInScreenState extends ConsumerState<EmailSignInScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  late bool isPasswordValid;

  void checkPassword(String password) {
    if (password.length <= 5) {
      setState(() {
        isPasswordValid = false;
      });
    } else {
      setState(() {
        isPasswordValid = true;
      });
    }
  }

  void signInWithEmail() async {
    FocusScope.of(context).unfocus();
    final result = await ref
        .read(authControllerProvider.notifier)
        .signInWithEmailAndPassword(
          emailController.text.toLowerCase().trim(),
          passwordController.text,
        );
    result.fold((l) {
      if (context.mounted) {
        showToast(false, l.message);
      }
    }, (_) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    });
  }

  void navigateToSignUpScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const EmailSignUpScreen()),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    isPasswordValid = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isLoading = ref.watch(authControllerProvider);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Scaffold(
          appBar: AppBar(
            title: Image.asset(
              Constants.logoPath,
              height: 45,
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () => navigateToSignUpScreen(context),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(
                height: 30,
              ),
              const Text(
                'Hi our old friend, let\'s sign you back in!',
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 40),

              //email input field
              Padding(
                padding: const EdgeInsets.only(
                  right: 30,
                  left: 30,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextFormField(
                    controller: emailController,
                    obscureText: false,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: Color(0xFF38464E),
                      ),
                      hintText: 'johndoe@example.com',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              //password input field
              Padding(
                padding: const EdgeInsets.only(
                  right: 30,
                  left: 30,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(
                        color: Color(0xFF38464E),
                      ),
                      hintText: '***********',
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isPasswordValid ? Colors.grey : Colors.red,
                        ),
                      ),
                      errorText: isPasswordValid ? null : 'Invalid Email',
                    ),
                    onChanged: (value) {
                      checkPassword(value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              //submit sign up request button
              Padding(
                padding: const EdgeInsets.only(
                  right: 30,
                  left: 30,
                ),
                child: ElevatedButton(
                  onPressed: isLoading
                      ? () {}
                      : () {
                          signInWithEmail();
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Pallete.blueColor,
                  ),
                  child: isLoading
                      ? const Loading()
                      : const Text(
                          'Let\'s Go',
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

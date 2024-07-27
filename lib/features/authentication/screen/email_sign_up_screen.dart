import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_in_screen.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/theme/pallette.dart';

class EmailSignUpScreen extends ConsumerStatefulWidget {
  const EmailSignUpScreen({
    super.key,
    BuildContext? context,
  });

  @override
  EmailSignUpScreenState createState() {
    return EmailSignUpScreenState();
  }
}

class EmailSignUpScreenState extends ConsumerState<EmailSignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  bool isPressed = false;
  bool isEmailValid = true;
  bool isNameValid = true;
  bool isPasswordValid = true;

  void checkName(String name) async {
    if (name.length < 5) {
      setState(() {
        isNameValid = false;
      });
    }
    final result = await checkExistingUserNameWhenSignUp(name.trim());
    result.fold((l) {}, (r) {
      setState(() {
        isNameValid = r;
      });
    });
  }

  void checkEmail(String email) async {
    if (email.length < 5) {
      setState(() {
        isEmailValid = false;
      });
    }
    final result =
        await checkExistingEmailWhenSignUp(email.trim().toLowerCase());
    result.fold((l) {}, (r) {
      setState(() {
        isEmailValid = r;
      });
    });
  }

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

  void signUpWithEmailAndPassword() async {
    setState(() {
      isPressed = true;
    });
    final user = await ref
        .read(authControllerProvider.notifier)
        .signUpWithEmailAndPassword(
          emailController.text.toLowerCase().trim(),
          passwordController.text,
          nameController.text.trim().toLowerCase(),
        );
    user.fold((l) {
      if (context.mounted) {
        showToast(false, l.message);
        setState(() {
          isPressed = false;
        });
      }
    }, (r) {
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  void navigateToSignInScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const EmailSignInScreen()),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: () => navigateToSignInScreen(context),
                child: const Text(
                  'Sign In',
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
                'Hi new friend, let\'s create your account!',
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
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(
                        color: Color(0xFF38464E),
                      ),
                      hintText: 'johndoe@example.com',
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isEmailValid ? Colors.grey : Colors.red,
                        ),
                      ),
                      errorText: isEmailValid ? null : 'Invalid Email',
                    ),
                    onChanged: (value) {
                      checkEmail(value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              //name input field
              Padding(
                padding: const EdgeInsets.only(
                  right: 30,
                  left: 30,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextFormField(
                    controller: nameController,
                    obscureText: false,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: const TextStyle(
                        color: Color(0xFF38464E),
                      ),
                      hintText: 'JohnDoe',
                      prefixText: '#',
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isNameValid ? Colors.grey : Colors.red,
                        ),
                      ),
                      errorText: isNameValid ? null : 'Invalid Username',
                    ),
                    onChanged: (value) {
                      checkName(value);
                    },
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
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    if (isEmailValid && isNameValid) {
                      signUpWithEmailAndPassword();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor: Pallete.blueColor,
                  ),
                  child: isPressed
                      ? const CircularProgressIndicator()
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

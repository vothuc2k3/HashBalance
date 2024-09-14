// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_up_screen.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/theme/pallette.dart';
import 'package:rive/rive.dart';

class EmailSignInScreen extends ConsumerStatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  EmailSignInScreenState createState() => EmailSignInScreenState();
}

class EmailSignInScreenState extends ConsumerState<EmailSignInScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  late bool isPasswordValid;

  FocusNode emailFocusNode = FocusNode();
  TextEditingController email = TextEditingController();

  FocusNode passwordFocusNode = FocusNode();
  TextEditingController password = TextEditingController();

  StateMachineController? controller;
  SMIInput<bool>? isChecking;
  SMIInput<double>? numLook;
  SMIInput<bool>? isHandsUp;

  SMIInput<bool>? trigSuccess;
  SMIInput<bool>? trigFail;

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
        .watch(authControllerProvider.notifier)
        .signInWithEmailAndPassword(
          emailController.text.toLowerCase().trim(),
          passwordController.text,
        );
    result.fold((l) {
      if (context.mounted) {
        showToast(false, l.message);
      }
    }, (_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    });
  }

  void navigateToSignUpScreen(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const EmailSignUpScreen(),
      ),
    );
  }

  void emailFocus() {
    isChecking?.change(emailFocusNode.hasFocus);
  }

  void passwordFocus() {
    isHandsUp?.change(passwordFocusNode.hasFocus);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.removeListener(emailFocus);
    passwordFocusNode.removeListener(passwordFocus);
    super.dispose();
  }

  @override
  void initState() {
    emailFocusNode.addListener(emailFocus);
    passwordFocusNode.addListener(passwordFocus);
    isPasswordValid = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isLoading = ref.watch(authControllerProvider);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF8c336b),
          ),
          child: Column(
            children: [
              const SizedBox(
                height: 40,
              ),
              const Text(
                'Hi our old friend, let\'s sign you back in!',
                style: TextStyle(
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 40),
              //MARK: - animation character
              SizedBox(
                width: 250,
                height: 250,
                child: RiveAnimation.asset(
                  fit: BoxFit.fitHeight,
                  stateMachines: const ["Login Machine"],
                  onInit: ((artboard) {
                    controller = StateMachineController.fromArtboard(
                        artboard, "Login Machine");
                    if (controller == null) return;
                    artboard.addController(controller!);
                    isChecking = controller?.findInput("isChecking");
                    numLook = controller?.findInput("numLook");
                    isHandsUp = controller?.findInput("isHandsUp");
                    trigSuccess = controller?.findInput("trigSuccess");
                    trigFail = controller?.findInput("trigFail");
                  }),
                  'assets/images/Login_character/character.riv',
                ),
              ),
              //MARK: - email input field
              Padding(
                padding: const EdgeInsets.only(
                  right: 30,
                  left: 30,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextFormField(
                    focusNode: emailFocusNode,
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
                    onChanged: (value) {
                      numLook?.change(value.length.toDouble());
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              //MARK: - password input field
              Padding(
                padding: const EdgeInsets.only(
                  right: 30,
                  left: 30,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: TextFormField(
                    focusNode: passwordFocusNode,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_in_screen.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:rive/rive.dart';

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
  bool isPressed = false;
  bool isEmailValid = true;
  bool isNameValid = true;
  bool isPasswordValid = true;
  bool isConfirmPasswordValid = true;
  FocusNode emailFocusNode = FocusNode();
  TextEditingController email = TextEditingController();

  bool isPasswordObscured = true;
  bool isConfirmPasswordObscured = true;

  FocusNode userNameFocusNode = FocusNode();
  TextEditingController userName = TextEditingController();

  FocusNode passwordFocusNode = FocusNode();
  TextEditingController password = TextEditingController();

  FocusNode confirmPasswordFocusNode = FocusNode();
  TextEditingController confirmPassword = TextEditingController();

  StateMachineController? controller;
  SMIInput<bool>? isChecking;
  SMIInput<double>? numLook;
  SMIInput<bool>? isHandsUp;

  SMIInput<bool>? trigSuccess;
  SMIInput<bool>? trigFail;

  void checkConfirmPassword(String confirmPassword) {
    if (confirmPassword.length < 5) {
      setState(() {
        isConfirmPasswordValid = false;
      });
    } else if (confirmPassword != password.text) {
      setState(() {
        isConfirmPasswordValid = false;
      });
    } else {
      setState(() {
        isConfirmPasswordValid = true;
      });
    }
  }

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
          email.text.toLowerCase().trim(),
          password.text,
          userName.text.trim().toLowerCase(),
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
        showToast(true, 'Welcome ${r.name}');
        Navigator.of(context).pushAndRemoveUntil(
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

  void emailFocus() {
    isChecking?.change(emailFocusNode.hasFocus);
  }

  void userNameFocus() {
    isChecking?.change(userNameFocusNode.hasFocus);
  }

  void passwordFocus() {
    isHandsUp?.change(passwordFocusNode.hasFocus);
  }

  void confirmPasswordFocus() {
    isHandsUp?.change(confirmPasswordFocusNode.hasFocus);
  }

  @override
  void initState() {
    super.initState();
    emailFocusNode.addListener(emailFocus);
    userNameFocusNode.addListener(userNameFocus);
    passwordFocusNode.addListener(passwordFocus);
    confirmPasswordFocusNode.addListener(confirmPasswordFocus);
  }

  @override
  void dispose() {
    email.dispose();
    userName.dispose();
    password.dispose();
    confirmPassword.dispose();
    emailFocusNode.removeListener(emailFocus);
    userNameFocusNode.removeListener(userNameFocus);
    passwordFocusNode.removeListener(passwordFocus);
    confirmPasswordFocusNode.removeListener(confirmPasswordFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Hi new friend'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              height: screenHeight,
              decoration: const BoxDecoration(
                color: Color(0xFF8c336b),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  //MARK: - animation character
                  SizedBox(
                    width: screenWidth * 0.6,
                    height: screenHeight * 0.3,
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
                  SizedBox(height: screenHeight * 0.01),
                  // Email input field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: TextFormField(
                      focusNode: emailFocusNode,
                      controller: email,
                      obscureText: false,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(
                          color: Colors.white70,
                        ),
                        hintText: 'johndoe@example.com',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF8C336B),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF8C336B), width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        numLook?.change(value.length.toDouble());
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Username input field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: TextFormField(
                      focusNode: userNameFocusNode,
                      controller: userName,
                      obscureText: false,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: const TextStyle(
                          color: Colors.white70,
                        ),
                        hintText: 'JohnDoe',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF8C336B),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF8C336B), width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        numLook?.change(value.length.toDouble());
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password input field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: TextFormField(
                      focusNode: passwordFocusNode,
                      controller: password,
                      obscureText: isPasswordObscured,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(
                          color: Colors.white70,
                        ),
                        hintText: '********',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF8C336B),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF8C336B), width: 2),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordObscured
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordObscured = !isPasswordObscured;
                            });
                          },
                        ),
                      ),
                      onChanged: (value) {
                        numLook?.change(value.length.toDouble());
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: TextFormField(
                      focusNode: confirmPasswordFocusNode,
                      controller: confirmPassword,
                      obscureText: isConfirmPasswordObscured,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        labelStyle: const TextStyle(
                          color: Colors.white70,
                        ),
                        hintText: '********',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF8C336B),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFF8C336B), width: 2),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isConfirmPasswordObscured
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              isConfirmPasswordObscured =
                                  !isConfirmPasswordObscured;
                            });
                          },
                        ),
                      ),
                      onChanged: (value) {
                        numLook?.change(value.length.toDouble());
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Submit button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: ElevatedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        checkName(userName.text);
                        checkPassword(password.text);
                        checkConfirmPassword(confirmPassword.text);
                        if (!isNameValid) {
                          showToast(false, 'Please enter a valid username');
                        } else if (!isPasswordValid) {
                          showToast(false, 'Please enter a valid password');
                        } else if (!isConfirmPasswordValid) {
                          showToast(false, 'Password does not match');
                        } else {
                          signUpWithEmailAndPassword();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(screenWidth * 0.8, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: const Color(0xFF592044),
                        shadowColor: Colors.black.withOpacity(0.2),
                        elevation: 5,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: isPressed
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
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/authentication/controller/auth_controller.dart';
import 'package:hash_balance/features/authentication/screen/email_sign_in_screen.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/theme/pallette.dart';
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

  FocusNode emailFocusNode = FocusNode();
  TextEditingController email = TextEditingController();

  FocusNode userNameFocusNode = FocusNode();
  TextEditingController userName = TextEditingController();

  FocusNode passwordFocusNode = FocusNode();
  TextEditingController password = TextEditingController();

  StateMachineController? controller;
  SMIInput<bool>? isChecking;
  SMIInput<double>? numLook;
  SMIInput<bool>? isHandsUp;

  SMIInput<bool>? trigSuccess;
  SMIInput<bool>? trigFail;

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

  @override
  void initState() {
    super.initState();
    emailFocusNode.addListener(emailFocus);
    userNameFocusNode.addListener(userNameFocus);
    passwordFocusNode.addListener(passwordFocus);
  }

  @override
  void dispose() {
    email.dispose();
    userName.dispose();
    password.dispose();
    emailFocusNode.removeListener(emailFocus);
    userNameFocusNode.removeListener(userNameFocus);
    passwordFocusNode.removeListener(passwordFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent, // AppBar trong suốt
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF8c336b),
          ),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Hi new friend, let\'s create your account!',
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

              // Email input field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: TextFormField(
                  focusNode: emailFocusNode,
                  controller: email,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Color(0xFF38464E)),
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
                    numLook?.change(value.length.toDouble());
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Username input field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: TextFormField(
                  focusNode: userNameFocusNode,
                  controller: userName,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: const TextStyle(color: Color(0xFF38464E)),
                    hintText: 'JohnDoe',
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
                    numLook?.change(value.length.toDouble());
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Password input field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: TextFormField(
                  focusNode: passwordFocusNode,
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Color(0xFF38464E)),
                    hintText: '***********',
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isPasswordValid ? Colors.grey : Colors.red,
                      ),
                    ),
                    errorText: isPasswordValid ? null : 'Invalid Password',
                  ),
                  onChanged: (value) {
                    checkPassword(value);
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
                    if (!isEmailValid) {
                      showToast(false, 'Please enter a valid email');
                    } else if (!isNameValid) {
                      showToast(false, 'Please enter a valid username');
                    } else if (!isPasswordValid) {
                      showToast(false, 'Please enter a valid password');
                    } else {
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

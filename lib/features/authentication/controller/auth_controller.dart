import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/models/user_model.dart';

final authControllerProvider = StateNotifierProvider<AuthController, bool>(
  (ref) => AuthController(
    authRepository: ref.read(authRepositoryProvider),
    ref: ref,
  ),
);

final authStageChangeProvider = StreamProvider((ref) {
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.authStageChange;
});

final getUserDataProvider = StreamProvider.family((ref, String uid) {
  final authController = ref.watch(authControllerProvider.notifier);
  return authController.getUserData(uid);
});

class AuthController extends StateNotifier<bool> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthController({required AuthRepository authRepository, required Ref ref})
      : _authRepository = authRepository,
        _ref = ref,
        super(false);

  Stream<User?> get authStageChange => _authRepository.authStageChange;

  //sign in with google in controller
  void signInWithGoogle(BuildContext context) async {
    state = true;
    final user = await _authRepository.signInWithGoogle();
    state = false;
    user.fold(
      (error) {
        return showSnackBar(
          context,
          error.message,
        );
      },
      (userModel) {
        _ref.read(userProvider.notifier).update(
              (state) => userModel,
            );
      },
    );
  }

  //sign up with email in controller
  void signUpWithEmailAndPassword(
    BuildContext context,
    String email,
    String password,
    String name,
  ) async {
    state = true;

    UserModel userModel = UserModel(
      email: email,
      password: password,
      name: name,
      uid: '',
      profileImage: Constants.avatarDefault,
      bannerImage: Constants.bannerDefault,
      isAuthenticated: true,
      activityPoint: 0,
      achivements: ['New boy'],
    );
    final user = await _authRepository.signUpWithEmailAndPassword(userModel);
    state = false;
    user.fold(
      (error) {
        return showSnackBar(
          context,
          error.message,
        );
      },
      (userModel) {
        _ref.read(userProvider.notifier).update(
              (state) => userModel,
            );
      },
    );
  }

  void signInWithEmailAndPassword(
      BuildContext context, String email, String password) async {
    state = true;
    final user =
        await _authRepository.signInWithEmailAndPassword(email, password);
    state = false;
    user.fold(
      (error) {
        return showSnackBar(
          context,
          error.message,
        );
      },
      (userModel) {
        _ref.read(userProvider.notifier).update(
              (state) => userModel,
            );
      },
    );
  }

  Stream<UserModel> getUserData(String uid) {
    return _authRepository.getUserData(uid);
  }
}

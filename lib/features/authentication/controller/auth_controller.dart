import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

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

  AuthController({
    required AuthRepository authRepository,
    required Ref ref,
  })  : _authRepository = authRepository,
        _ref = ref,
        super(false);

  Stream<User?> get authStageChange => _authRepository.authStageChange;

  //SIGN THE USER IN WITH GOOGLE
  FutureUserModel signInWithGoogle() async {
    state = true;
    try {
      final result = await _authRepository.signInWithGoogle();
      return result.fold((l) => left(Failures(l.message)), (userModel) {
        _ref.read(userProvider.notifier).update((state) => userModel);
        return right(userModel);
      });
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  //SIGN UP WITH EMAIL AND PASSWORD
  FutureUserModel signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    state = true;
    try {
      UserModel userModel = UserModel(
        email: email,
        password: password,
        name: name,
        uid: '',
        profileImage: Constants
            .avatarDefault[Random().nextInt(Constants.avatarDefault.length)],
        bannerImage: Constants.bannerDefault,
        isAuthenticated: true,
        activityPoint: 0,
        createdAt: Timestamp.now(),
        hashAge: 0,
        isRestricted: false,
        bio: 'New user',
        description: 'Nothing, I\'m a new user here....',
      );
      final result =
          await _authRepository.signUpWithEmailAndPassword(userModel);
      return result.fold((l) => left(Failures(l.message)), (userModel) {
        _ref.read(userProvider.notifier).update((state) => userModel);
        return right(userModel);
      });
    } on FirebaseAuthException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  //SIGN IN WITH EMAIL AND PASSWORD
  FutureUserModel signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    state = true;
    try {
      final result =
          await _authRepository.signInWithEmailAndPassword(email, password);
      return result.fold((l) => left(Failures(l.message)), (userModel) {
        _ref.read(userProvider.notifier).update((state) => userModel);
        return right(userModel);
      });
    } on FirebaseAuthException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  void signOut(WidgetRef ref) {
    final uid = _ref.watch(userProvider)!.uid;
    _authRepository.signOut(ref, uid);

  }

  FutureString changeUserPrivacy({
    required bool setting,
    required UserModel user,
  }) async {
    state = true;
    try {
      final result = await _authRepository.changeUserPrivacy(
        setting: setting,
        user: user,
      );
      return result.fold((l) => left(Failures(l.message)),
          (r) => right('Successfully Updated User Privacy Setting!'));
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  Stream<UserModel> getUserData(String uid) {
    return _authRepository.getUserData(uid);
  }
}

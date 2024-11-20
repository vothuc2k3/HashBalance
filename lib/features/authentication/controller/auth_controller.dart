import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/user_devices/controller/user_device_controller.dart';
import 'package:hash_balance/models/user_model.dart';

final fetchUserDataProvider = FutureProviderFamily((ref, String uid) {
  return ref.watch(authControllerProvider.notifier).fetchUserData(uid);
});

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
  Future<Either<Failures, UserModel>> signInWithGoogle() async {
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
  Future<Either<Failures, UserModel>> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    state = true;
    try {
      final userModel = UserModel(
        email: email,
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

      final result = await _authRepository.signUpWithEmailAndPassword(
        userModel,
        password,
      );
      return result.fold(
          (l) => left(
                Failures(
                  l.message,
                ),
              ), (r) {
        _ref.watch(userProvider.notifier).update(
              (state) => userModel,
            );
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
  Future<Either<Failures, UserModel>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    state = true;
    try {
      final result =
          await _authRepository.signInWithEmailAndPassword(email, password);
      return result.fold((l) => left(Failures(l.message)), (userModel) async {
        _ref.watch(userProvider.notifier).update((state) => userModel);
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

  Future<void> signOut(String uid) async {
    state = true;
    try {
      await _authRepository.signOut();
      final token = await _ref.read(firebaseMessagingProvider).getToken();
      await _ref.read(userDeviceControllerProvider).removeUserDeviceToken(
            uid: uid,
            deviceToken: token ?? '',
          );
    } catch (e) {
      throw Exception(e.toString());
    } finally {
      state = false;
    }
  }

  Stream<UserModel> getUserData(String uid) {
    return _authRepository.getUserData(uid);
  }

  Future<UserModel> fetchUserData(String uid) async {
    return _authRepository.fetchUserData(uid);
  }

  Future<Either<Failures, void>> sendResetPasswordLink(String email) async {
    state = true;
    try {
      await _authRepository.sendResetPasswordLink(email);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }
}

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/features/user_profile/repository/user_repository.dart';
import 'package:hash_balance/models/user_model.dart';

final userControllerProvider = StateNotifierProvider<UserController, bool>(
  (ref) => UserController(
    userRepository: ref.read(userRepositoryProvider),
  ),
);

final getUserByUidProvider = StreamProvider.family((ref, String uid) {
  return ref.watch(userControllerProvider.notifier).getUserByUid(uid);
});

final getUserDeviceTokensProvider = FutureProvider.family((ref, String uid) =>
    ref.watch(userControllerProvider.notifier).getUserDeviceTokens(uid));

class UserController extends StateNotifier<bool> {
  final UserRepository _userRepository;

  UserController({
    required UserRepository userRepository,
  })  : _userRepository = userRepository,
        super(false);

  FutureString editUserProfile(
    UserModel user,
    File? profileImage,
    File? bannerImage,
    String? name,
    String? bio,
    String? description,
  ) async {
    state = true;
    try {
      final result = await _userRepository.editUserProfile(
          user, profileImage, bannerImage, name, bio, description);
      return result.fold(
        (l) => left((Failures(l.message))),
        (r) => right('Successfully Updated Your Profile'),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }

  Stream<UserModel> getUserByUid(String uid) {
    return _userRepository.getUserByUid(uid);
  }

  Future<List<String>> getUserDeviceTokens(String uid) async {
    return await _userRepository.getUserDeviceTokens(uid);
  }

  Future<UserModel> fetchUserByUidProvider(String uid) async {
    try {
      return await _userRepository.fetchUserByUidProvider(uid);
    } on FirebaseException catch (e) {
      throw e.message!;
    } catch (e) {
      throw e.toString();
    }
  }
}

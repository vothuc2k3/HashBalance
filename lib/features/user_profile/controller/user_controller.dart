import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/features/cloud_vision/controller/cloud_vision_controller.dart';
import 'package:hash_balance/features/user_profile/repository/user_repository.dart';
import 'package:hash_balance/models/block_model.dart';
import 'package:hash_balance/models/conbined_models/user_profile_data_model.dart';
import 'package:hash_balance/models/conbined_models/timeline_item_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:uuid/uuid.dart';

final followingProvider =
    FutureProvider.family<Either<Failures, List<UserModel>>, String>(
  (ref, String uid) =>
      ref.watch(userControllerProvider.notifier).getCurrentUserFollowing(uid),
);

final followersProvider =
    FutureProvider.family<Either<Failures, List<UserModel>>, String>(
  (ref, String uid) =>
      ref.watch(userControllerProvider.notifier).getCurrentUserFollowers(uid),
);

final userTimelineProvider = StreamProvider.family((ref, UserModel user) {
  return ref.watch(userControllerProvider.notifier).getUserTimelineItems(user);
});

final userProfileDataProvider =
    StreamProvider.family<UserProfileDataModel, String>(
  (ref, String uid) =>
      ref.watch(userControllerProvider.notifier).getUserProfileData(uid),
);

final userControllerProvider = StateNotifierProvider<UserController, bool>(
  (ref) => UserController(
    userRepository: ref.read(userRepositoryProvider),
    cloudVisionController: ref.read(cloudVisionControllerProvider),
  ),
);

class UserController extends StateNotifier<bool> {
  final UserRepository _userRepository;
  final CloudVisionController _cloudVisionController;
  final _uuid = const Uuid();
  UserController({
    required UserRepository userRepository,
    required CloudVisionController cloudVisionController,
  })  : _userRepository = userRepository,
        _cloudVisionController = cloudVisionController,
        super(false);

  Future<Either<Failures, String>> editUserProfile(
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

  Future<UserModel> fetchUserByUidProvider(String uid) async {
    try {
      return await _userRepository.fetchUserByUidProvider(uid);
    } on FirebaseException catch (e) {
      throw e.message!;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<Either<Failures, void>> uploadProfileImage(
    UserModel user,
    File profileImage,
  ) async {
    try {
      final result = await _cloudVisionController.areImagesSafe([profileImage]);
      final isSafe = result.fold(
        (failure) => left(failure),
        (isSafe) => right(isSafe),
      );
      if (isSafe.isLeft()) return isSafe as Either<Failures, void>;
      if (isSafe.isRight() && !isSafe.getOrElse((_) => false)) {
        return left(Failures('Your image contains inappropriate content...'));
      }
      return await _userRepository.uploadProfileImage(user, profileImage);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> uploadBannerImage(
    UserModel user,
    File bannerImage,
  ) async {
    try {
      final result = await _cloudVisionController.areImagesSafe([bannerImage]);
      final isSafe = result.fold(
        (failure) => left(failure),
        (isSafe) => right(isSafe),
      );
      if (isSafe.isLeft()) return isSafe as Either<Failures, void>;
      if (isSafe.isRight() && !isSafe.getOrElse((_) => false)) {
        return left(Failures('Your image contains inappropriate content...'));
      }
      return await _userRepository.uploadBannerImage(user, bannerImage);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> editName(
    UserModel user,
    String name,
  ) async {
    if (name.isEmpty) return left(Failures('Name cannot be empty'));
    if (name.length > 22) {
      return left(Failures('Name cannot be longer than 22 characters'));
    }
    if (name.length < 3) {
      return left(Failures('Name cannot be shorter than 3 characters'));
    }
    try {
      return await _userRepository.editName(user, name);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> editBio(
    UserModel user,
    String bio,
  ) async {
    try {
      return await _userRepository.editBio(user, bio);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> editDescription(
    UserModel user,
    String description,
  ) async {
    try {
      return await _userRepository.editDescription(user, description);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    }
  }

  Stream<UserProfileDataModel> getUserProfileData(String uid) {
    return _userRepository.getUserProfileData(uid);
  }

  Stream<List<TimelineItem>> getUserTimelineItems(UserModel user) {
    return _userRepository.getUserTimelineItems(user);
  }

  Future<Either<Failures, void>> blockUser({
    required String currentUid,
    required String blockUid,
  }) async {
    final blockModel = BlockModel(
      id: _uuid.v1(),
      uid: currentUid,
      blockUid: blockUid,
      createdAt: Timestamp.now(),
    );
    return await _userRepository.blockUser(blockModel);
  }

  Future<Either<Failures, void>> unblockUser({
    required String currentUid,
    required String blockUid,
  }) async {
    return await _userRepository.unblockUser(
      currentUid: currentUid,
      blockUid: blockUid,
    );
  }

  Future<List<String>> getUserJoinedCommunitiesIds(String uid) async {
    return await _userRepository.getUserJoinedCommunitiesIds(uid);
  }

  Future<Either<Failures, void>> updateUserPrivacy(UserModel user) async {
    return await _userRepository.updateUserPrivacy(user);
  }

  Future<Either<Failures, List<UserModel>>> getCurrentUserFollowers(
      String uid) async {
    return await _userRepository.getCurrentUserFollowers(uid);
  }

  Future<Either<Failures, List<UserModel>>> getCurrentUserFollowing(
      String uid) async {
    return await _userRepository.getCurrentUserFollowing(uid);
  }
}

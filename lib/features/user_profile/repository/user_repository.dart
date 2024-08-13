import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/user_model.dart';

final userRepositoryProvider = Provider((ref) {
  return UserRepository(
      firestore: ref.read(firebaseFirestoreProvider),
      storageRepository: ref.read(storageRepositoryProvider));
});

class UserRepository {
  final FirebaseFirestore _firestore;
  final StorageRepository _storageRepository;

  UserRepository({
    required FirebaseFirestore firestore,
    required StorageRepository storageRepository,
  })  : _firestore = firestore,
        _storageRepository = storageRepository;

  //EDIT USER PROFLE
  FutureVoid editUserProfile(
    UserModel user,
    File? profileImage,
    File? bannerImage,
    String? name,
    String? bio,
    String? description,
  ) async {
    try {
      UserModel updatedUser = user;
      if (profileImage != null) {
        final result = await _storageRepository.storeFile(
          path: 'users/profile',
          id: user.uid,
          file: profileImage,
        );
        await result.fold(
          (error) => throw FirebaseException(
            plugin: 'Firebase Exception',
            message: error.message,
          ),
          (right) async {
            String profileImageUrl = await FirebaseStorage.instance
                .ref('users/profile/${user.uid}')
                .getDownloadURL();
            updatedUser = updatedUser.copyWith(profileImage: profileImageUrl);
          },
        );
      }
      if (bannerImage != null) {
        final result = await _storageRepository.storeFile(
          path: 'users/banner',
          id: user.uid,
          file: bannerImage,
        );
        await result.fold(
            (error) => throw FirebaseException(
                  plugin: 'Firebase Exception',
                  message: error.message,
                ), (right) async {
          String bannerImageUrl = await FirebaseStorage.instance
              .ref('users/banner/${user.uid}')
              .getDownloadURL();
          updatedUser = updatedUser.copyWith(bannerImage: bannerImageUrl);
        });
      }
      if (name != null) {
        updatedUser = updatedUser.copyWith(name: name);
      }
      if (bio != null) {
        updatedUser = updatedUser.copyWith(bio: bio);
      }
      if (description != null) {
        updatedUser = updatedUser.copyWith(description: description);
      }
      final updatedUserAfterCast = {
        'email': updatedUser.email,
        'name': updatedUser.name,
        'uid': updatedUser.uid,
        'createdAt': updatedUser.createdAt,
        'profileImage': updatedUser.profileImage,
        'bannerImage': updatedUser.bannerImage,
        'isAuthenticated': updatedUser.isAuthenticated,
        'isRestricted': updatedUser.isRestricted,
        'activityPoint': updatedUser.activityPoint,
        'hashAge': updatedUser.hashAge,
        'bio': updatedUser.bio,
        'description': updatedUser.description,
      };
      await _user.doc(user.uid).update(updatedUserAfterCast);
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<UserModel> getUserByUid(String uid) {
    return _user.doc(uid).snapshots().map((event) {
      return UserModel.fromMap(event.data() as Map<String, dynamic>);
    });
  }

  Future<List<String>> getUserDeviceTokens(String uid) async {
    final userDeviceDocs =
        await _userDevices.where('uid', isEqualTo: uid).get();
    var deviceTokens = <String>[];
    for (var doc in userDeviceDocs.docs) {
      final docData = doc.data() as Map<String, dynamic>;
      deviceTokens.add(docData['deviceToken']);
    }
    return deviceTokens;
  }

  Future<UserModel> fetchUserByUidProvider(String uid) async {
    try {
      final userDoc = await _user.doc(uid).get();
      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
    } on FirebaseException catch (e) {
      throw e.message!;
    } catch (e) {
      throw e.toString();
    }
  }

  //REFERENCE ALL THE USERS
  CollectionReference get _user =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //REFERENCE ALL THE USERS
  CollectionReference get _userDevices =>
      _firestore.collection(FirebaseConstants.userDevicesCollection);
}

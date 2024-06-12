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
                ), (right) async {
          String profileImageUrl = await FirebaseStorage.instance
              .ref('users/profile/${user.uid}')
              .getDownloadURL();
          updatedUser = updatedUser.copyWith(profileImage: profileImageUrl);
        });
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
      final Map<String, dynamic> updatedUserAfterCast = {
        'email': updatedUser.email,
        'password': updatedUser.password,
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
        'achivements': List<String>.from(updatedUser.achivements).toList(),
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
      return UserModel(
        email: event['email'] as String,
        name: event['name'] as String,
        uid: uid,
        createdAt: event['createdAt'] as Timestamp,
        profileImage: event['profileImage'] as String,
        bannerImage: event['bannerImage'] as String,
        isAuthenticated: event['isAuthenticated'] as bool,
        isRestricted: event['isRestricted'] as bool,
        activityPoint: event['activityPoint'] as int,
        achivements: List<String>.from(event['achivements']).toList(),
        friends: List<String>.from(event['friends']).toList(),
        followers: List<String>.from(event['followers']).toList(),
      );
    });
  }

  //SEND FRIEND REQUEST

  //REFERENCE ALL THE USERS
  CollectionReference get _user =>
      _firestore.collection(FirebaseConstants.usersCollection);
}

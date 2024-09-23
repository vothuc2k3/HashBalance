import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';
import 'package:hash_balance/models/block_model.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/user_profile_data_model.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

  //REFERENCE ALL THE USERS
  CollectionReference get _user =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //REFERENCE ALL THE USERS
  CollectionReference get _userDevices =>
      _firestore.collection(FirebaseConstants.userDevicesCollection);
  //REFERENCE ALL THE FRIENDSHIPS
  CollectionReference get _friendship =>
      _firestore.collection(FirebaseConstants.friendshipCollection);
  //REFERENCE ALL THE USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);
  //REFERENCE ALL THE FOLLOWERS
  CollectionReference get _follower =>
      _firestore.collection(FirebaseConstants.followerCollection);
  //REFERENCE ALL THE POSTS
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
  //REFERENCE ALL THE COMMUNITIES
  CollectionReference get _communities =>
      _firestore.collection(FirebaseConstants.communitiesCollection);
  //REFERENCE ALL THE BLOCKS
  CollectionReference get _blocks =>
      _firestore.collection(FirebaseConstants.blocksCollection);

  //EDIT USER PROFLE
  Future<Either<Failures, void>> editUserProfile(
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

  Future<String> getUserDeviceTokens(String uid) async {
    final userDeviceDocs =
        await _userDevices.where('uid', isEqualTo: uid).get();
    String? deviceToken;
    for (var doc in userDeviceDocs.docs) {
      final docData = doc.data() as Map<String, dynamic>;
      deviceToken = docData['deviceToken'];
    }
    return deviceToken ?? '';
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

  Future<Either<Failures, void>> uploadProfileImage(
      UserModel user, File profileImage) async {
    try {
      final result = await _storageRepository.storeFile(
        path: 'users/profile',
        id: user.uid,
        file: profileImage,
      );
      await result.fold(
          (l) => throw FirebaseException(
                plugin: 'Firebase Exception',
                message: l.message,
              ), (r) async {
        final profileImageUrl = await FirebaseStorage.instance
            .ref('users/profile/${user.uid}')
            .getDownloadURL();
        await _user.doc(user.uid).update({
          'profileImage': profileImageUrl,
        });
      });
      return right(null);
    } on FirebaseException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw e.message ?? 'Unknown FirebaseException error';
    } catch (e, stackTrace) {
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      throw e.toString();
    }
  }

  Future<Either<Failures, void>> uploadBannerImage(
      UserModel user, File bannerImage) async {
    try {
      final result = await _storageRepository.storeFile(
        path: 'users/banner',
        id: user.uid,
        file: bannerImage,
      );
      await result.fold(
          (l) => throw FirebaseException(
                plugin: 'Firebase Exception',
                message: l.message,
              ), (r) async {
        final bannerImageUrl = await FirebaseStorage.instance
            .ref('users/banner/${user.uid}')
            .getDownloadURL();
        await _user.doc(user.uid).update({
          'bannerImage': bannerImageUrl,
        });
      });
      return right(null);
    } on FirebaseException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw e.message ?? 'Unknown FirebaseException error';
    } catch (e, stackTrace) {
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      throw e.toString();
    }
  }

  Future<Either<Failures, void>> editName(UserModel user, String name) async {
    try {
      await _user.doc(user.uid).update({
        'name': name,
      });
      return right(null);
    } on FirebaseException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw e.message ?? 'Unknown FirebaseException error';
    } catch (e, stackTrace) {
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      throw e.toString();
    }
  }

  Future<Either<Failures, void>> editBio(UserModel user, String bio) async {
    try {
      await _user.doc(user.uid).update({
        'bio': bio,
      });
      return right(null);
    } on FirebaseException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw e.message ?? 'Unknown FirebaseException error';
    } catch (e, stackTrace) {
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      throw e.toString();
    }
  }

  Future<Either<Failures, void>> editDescription(
      UserModel user, String description) async {
    try {
      await _user.doc(user.uid).update({
        'description': description,
      });
      return right(null);
    } on FirebaseException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw e.message ?? 'Unknown FirebaseException error';
    } catch (e, stackTrace) {
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
      );
      throw e.toString();
    }
  }

  Stream<UserProfileDataModel> getUserProfileData(String uid) {
    return _user.doc(uid).snapshots().asyncMap((event) async {
      final friends = <UserModel>[];
      final followers = <UserModel>[];
      final following = <UserModel>[];

      // Truy vấn bạn bè của người dùng dựa trên uid1 và uid2
      final query1 = _friendship.where('uid1', isEqualTo: uid).get();
      final query2 = _friendship.where('uid2', isEqualTo: uid).get();
      final results = await Future.wait([query1, query2]);

      final documents = results.expand((result) => result.docs).toList();

      final friendUids = documents.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['uid1'] == uid ? data['uid2'] : data['uid1'];
      }).toList();

      if (friendUids.isNotEmpty) {
        final friendQuery =
            await _users.where(FieldPath.documentId, whereIn: friendUids).get();

        for (var doc in friendQuery.docs) {
          final friendUid = doc.id;
          final friendUser = await fetchUserByUidProvider(friendUid);
          friends.add(friendUser);
        }
      }

      final followerQuery =
          await _follower.where('targetUid', isEqualTo: uid).get();
      for (var doc in followerQuery.docs) {
        final followerData = doc.data() as Map<String, dynamic>;
        final followerUid = followerData['followerUid'];
        final followerUser = await fetchUserByUidProvider(followerUid);
        followers.add(followerUser);
      }

      final followingQuery =
          await _follower.where('followerUid', isEqualTo: uid).get();
      for (var doc in followingQuery.docs) {
        final followingData = doc.data() as Map<String, dynamic>;
        final followingUid = followingData['targetUid'];
        final followingUser = await fetchUserByUidProvider(followingUid);
        following.add(followingUser);
      }

      return UserProfileDataModel(
        friends: friends,
        followers: followers,
        following: following,
      );
    });
  }

  Stream<List<PostDataModel>> getUserPosts(UserModel user) {
    try {
      return _posts
          .where('uid', isEqualTo: user.uid)
          .where('status', isEqualTo: 'Approved')
          .snapshots() // Sử dụng snapshots để lắng nghe thay đổi
          .asyncMap((userPosts) async {
        final List<PostDataModel> postDataModels = [];

        for (final postDoc in userPosts.docs) {
          final postData = Post.fromMap(postDoc.data() as Map<String, dynamic>);

          final communityDoc =
              await _communities.doc(postData.communityId).get();
          final communityData =
              Community.fromMap(communityDoc.data() as Map<String, dynamic>);

          postDataModels.add(
            PostDataModel(
              post: postData,
              community: communityData,
            ),
          );
        }

        // Sắp xếp bài post theo createdAt
        postDataModels
            .sort((a, b) => b.post.createdAt.compareTo(a.post.createdAt));

        return postDataModels; // Trả về danh sách bài viết đã được sắp xếp
      });
    } on FirebaseException catch (e) {
      throw e.toString();
    }
  }

  Future<Either<Failures, void>> clearUserDeviceToken(String uid) async {
    try {
      await _userDevices.doc(uid).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> blockUser(BlockModel blockModel) async {
    try {
      await _blocks.doc(blockModel.id).set(blockModel.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    }
  }

  Future<Either<Failures, void>> unblockUser({
    required String blockId,
  }) async {
    try {
      await _blocks.doc(blockId).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    }
  }
}

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';

final storageRepositoryProvider = Provider(
  (ref) => StorageRepository(
    firebaseStorage: ref.watch(firebaseStorageProvider),
  ),
);

class StorageRepository {
  final FirebaseStorage _firebaseStorage;

  StorageRepository({required FirebaseStorage firebaseStorage})
      : _firebaseStorage = firebaseStorage;

  Future<Either<Failures, String>> storeFile({
    required String path,
    required String id,
    required File? file,
  }) async {
    try {
      final ref = _firebaseStorage.ref().child(path).child(id);
      UploadTask uploadTask = ref.putFile(file!);
      final snapshot = await uploadTask;
      return right(
        await snapshot.ref.getDownloadURL(),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> deleteFile({
    required String path,
  }) async {
    try {
      _firebaseStorage.ref().child(path).delete();
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, String>> getDownloadURL({
    required String path,
  }) async {
    try {
      final url = await _firebaseStorage.ref(path).getDownloadURL();
      return right(url);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, void>> deletePostImagesAndVideo({
    required String postId,
  }) async {
    try {
      final imagesRef = _firebaseStorage.ref().child('posts/images/$postId');
      final videoRef = _firebaseStorage.ref().child('posts/videos/$postId');

      final imagesListResult = await imagesRef.listAll();
      for (var imageRef in imagesListResult.items) {
        await imageRef.delete();
      }

      final videoListResult = await videoRef.listAll();
      if (videoListResult.items.isNotEmpty) {
        await videoRef.delete();
      }

      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}

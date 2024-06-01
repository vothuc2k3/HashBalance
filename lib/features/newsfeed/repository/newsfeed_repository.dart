import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/firebase_constants.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/providers/storage_repository_providers.dart';

final newsfeedRepositoryProvider = Provider((ref) {
  return NewsfeedRepository(
      firestore: ref.read(firebaseFirestoreProvider),
      storageRepository: ref.read(storageRepositoryProvider));
});

class NewsfeedRepository {
  final FirebaseFirestore _firestore;
  final StorageRepository _storageRepository;

  NewsfeedRepository({
    required FirebaseFirestore firestore,
    required StorageRepository storageRepository,
  })  : _firestore = firestore,
        _storageRepository = storageRepository;

  //REFERENCE ALL THE POSTS
  CollectionReference get _posts =>
      _firestore.collection(FirebaseConstants.postsCollection);
}

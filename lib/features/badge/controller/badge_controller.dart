import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/storage_repository.dart';
import 'package:hash_balance/features/badge/repository/badge_repository.dart';
import 'package:hash_balance/models/badge_model.dart';
import 'package:uuid/uuid.dart';

final badgesProvider = StreamProvider<List<BadgeModel>>((ref) {
  return ref.watch(badgeControllerProvider.notifier).getBadges();
});

final badgeControllerProvider =
    StateNotifierProvider<BadgeController, bool>((ref) {
  return BadgeController(
    badgeRepository: ref.read(badgeRepositoryProvider),
    storageRepository: ref.read(storageRepositoryProvider),
    ref: ref,
  );
});

class BadgeController extends StateNotifier<bool> {
  final BadgeRepository _badgeRepository;
  final StorageRepository _storageRepository;
  final Uuid _uuid = const Uuid();

  BadgeController({
    required BadgeRepository badgeRepository,
    required StorageRepository storageRepository,
    required Ref ref,
  })  : _badgeRepository = badgeRepository,
        _storageRepository = storageRepository,
        super(false);

  Stream<List<BadgeModel>> getBadges() {
    return _badgeRepository.getBadges();
  }

  Future<Either<Failures, void>> createBadge({
    required String name,
    required int threshold,
    required String description,
    required File imageFile,
  }) async {
    state = true;
    try {
      final id = _uuid.v4();
      final uploadResult = await _storageRepository.storeFile(
        path: 'badges',
        id: id,
        file: imageFile,
      );
      final String imageUrl;
      final bool isSuccess = uploadResult.fold(
        (failure) => false,
        (imageUrl) => true,
      );
      if (!isSuccess) return left(Failures('Failed to upload image'));
      imageUrl = uploadResult.getOrElse((_) => '');
      return await _badgeRepository.createBadge(
        BadgeModel(
          id: id,
          name: name,
          threshold: threshold,
          description: description,
          imageUrl: imageUrl,
        ),
      );
    } on FirebaseException catch (e) {
      return left(Failures(e.message ?? "An unknown error occurred"));
    } on Exception catch (e) {
      return left(Failures(e.toString()));
    } finally {
      state = false;
    }
  }
}

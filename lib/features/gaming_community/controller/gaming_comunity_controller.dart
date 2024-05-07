import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/gaming_community/repository/gaming_community_repository.dart';
import 'package:hash_balance/models/gaming_community_model.dart';
import 'package:routemaster/routemaster.dart';

final gamingCommunityControllerProvider =
    StateNotifierProvider<GamingCommunityController, bool>((ref) {
  final gamingCommunityRepository =
      ref.watch(gamingCommunityRepositoryProvider);
  return GamingCommunityController(
    gamingCommunityRepository: gamingCommunityRepository,
    ref: ref,
  );
});

class GamingCommunityController extends StateNotifier<bool> {
  final GamingCommunityRepository _gamingCommunityRepository;
  final Ref _ref;

  GamingCommunityController({
    required GamingCommunityRepository gamingCommunityRepository,
    required Ref ref,
  })  : _gamingCommunityRepository = gamingCommunityRepository,
        _ref = ref,
        super(false);

  void createGamingCommunity(
    BuildContext context,
    String name,
    String type,
    bool containsExposureContents,
  ) async {
    state = true;

    final uid = _ref.read(userProvider)?.uid ?? '';

    GamingCommunityModel community = GamingCommunityModel(
      id: Timestamp.now().toString(),
      name: name,
      profileImage: Constants.avatarDefault,
      bannerImage: Constants.bannerDefault,
      type: type,
      containsExposureContents: containsExposureContents,
      members: [uid],
      mods: [uid],
    );

    final result =
        await _gamingCommunityRepository.createGamingCommunity(community);

    state = false;

    result.fold((error) {
      return showSnackBar(
        context,
        error.message,
      );
    }, (right) {
      showSnackBar(
        context,
        'Your Community Created Successfully. Have Fun!',
      );
      Routemaster.of(context).pop();
    });
  }
}

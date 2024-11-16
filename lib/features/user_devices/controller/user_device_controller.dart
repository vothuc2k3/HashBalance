import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/features/user_devices/repository/user_device_repository.dart';

final userDeviceControllerProvider = Provider<UserDeviceController>(
  (ref) => UserDeviceController(
    userDeviceRepository: ref.watch(userDeviceRepositoryProvider),
  ),
);

class UserDeviceController {
  final UserDeviceRepository _userDeviceRepository;

  UserDeviceController({
    required UserDeviceRepository userDeviceRepository,
  }) : _userDeviceRepository = userDeviceRepository;

  //ADD USER DEVICE
  Future<Either<Failures, void>> addUserDevice({
    required String uid,
    required String deviceToken,
  }) async {
    final result = await _userDeviceRepository.addUserDevice(
      uid: uid,
      deviceToken: deviceToken,
    );
    return result;
  }

  //REMOVE USER DEVICE
  Future<Either<Failures, void>> removeUserDeviceToken({
    required String uid,
    required String deviceToken,
  }) async {
    return await _userDeviceRepository.removeUserDeviceToken(
      uid: uid,
      deviceToken: deviceToken,
    );
  }

  //GET USER DEVICE TOKENS
  Future<Either<Failures, List<String>>> getUserDeviceTokens(String uid) async {
    return await _userDeviceRepository.getUserDeviceTokens(uid);
  }
}

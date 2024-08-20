import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/features/user_devices/repository/user_device_repository.dart';
import 'package:hash_balance/models/user_devices_model.dart';

final userDeviceControllerProvider = StateNotifierProvider<UserDeviceController, bool>(
  (ref) => UserDeviceController(
    userDeviceRepository: ref.watch(userDeviceRepositoryProvider),
  ),
);



class UserDeviceController extends StateNotifier<bool> {
  final UserDeviceRepository _userDeviceRepository;

  UserDeviceController({
    required UserDeviceRepository userDeviceRepository,
  })  : _userDeviceRepository = userDeviceRepository,
        super(false);

  //ADD USER DEVICE
  FutureVoid addUserDevice(UserDevices userDevice) async {
    state = true;
    final result = await _userDeviceRepository.addUserDevice(userDevice);
    state = false;
    return result;
  }

  //CHECK IF DEVICE EXISTS
  Future<bool> checkDeviceExists(String uid, String deviceToken) async {
    return await _userDeviceRepository.checkDeviceExists(uid, deviceToken);
  }
}

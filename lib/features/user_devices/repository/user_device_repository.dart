import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/core/type_defs.dart';
import 'package:hash_balance/models/user_devices_model.dart';

final userDeviceRepositoryProvider = Provider((ref) {
  return UserDeviceRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

class UserDeviceRepository {
  final FirebaseFirestore _firestore;

  UserDeviceRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  //ADD USER DEVICE
  FutureVoid addUserDevice(UserDevices userDevice) async {
    try {
      await _userDevices.doc(userDevice.uid).set(userDevice.toMap());
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //CHECK IF DEVICE EXISTS
  Future<bool> checkDeviceExists(String uid, String deviceToken) async {
    final deviceSnapshot = await _userDevices
        .where('uid', isEqualTo: uid)
        .where('deviceToken', isEqualTo: deviceToken)
        .get();

    return deviceSnapshot.docs.isNotEmpty;
  }

  //REFERENCE FOR USER DEVICES
  CollectionReference get _userDevices =>
      _firestore.collection(FirebaseConstants.userDevicesCollection);
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';

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

  //REFERENCE FOR USERS
  CollectionReference get _users =>
      _firestore.collection(FirebaseConstants.usersCollection);

  //ADD USER DEVICE
  Future<Either<Failures, void>> addUserDevice({
    required String uid,
    required String deviceToken,
  }) async {
    try {
      final userDoc = await _users.doc(uid).get();
      if (userDoc.exists) {
        final Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        List<String> userDevices =
            List<String>.from(userData['userDevices'] ?? []);
        if (!userDevices.contains(deviceToken)) {
          userDevices.add(deviceToken);
          await _users.doc(uid).update({'userDevices': userDevices});
        }
      } else {
        await _users.doc(uid).set({'userDevices': [deviceToken]});
      }
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //REMOVE USER DEVICE
  Future<Either<Failures, void>> removeUserDeviceToken({
    required String uid,
    required String deviceToken,
  }) async {
    try {
      final userDoc = await _users.doc(uid).get();
      if (userDoc.exists) {
        final Map<String, dynamic> userData =
            userDoc.data() as Map<String, dynamic>;
        List<String> userDevices =
            List<String>.from(userData['userDevices'] ?? []);
        userDevices.remove(deviceToken);
        await _users.doc(uid).update({'userDevices': userDevices});
      }
      return right(null);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  //GET USER DEVICE TOKENS
  Future<Either<Failures, List<String>>> getUserDeviceTokens(String uid) async {
    try {
      final userDoc = await _users.doc(uid).get();
      if (userDoc.exists) {
        final Map<String, dynamic> userData =
            userDoc.data() as Map<String, dynamic>;
        return right(List<String>.from(userData['userDevices'] ?? []));
      }
      return right([]);
    } on FirebaseException catch (e) {
      return left(Failures(e.message!));
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }
}

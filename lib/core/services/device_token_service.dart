import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/models/user_devices_model.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class DeviceTokenService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //REFERENCE ALL THE USERS DEVICES
  CollectionReference get _userDevices =>
      _firestore.collection(FirebaseConstants.userDevicesCollection);

  //UPDATE USER DEVICE TOKEN
  Future<void> updateUserDeviceToken(UserModel? userData) async {
    if (userData != null) {
      final currentDeviceToken = await _firebaseMessaging.getToken();
      if (currentDeviceToken != null) {
        _userDevices.doc(userData.uid).snapshots().listen((event) async {
          if (event.exists) {
            final data = event.data() as Map<String, dynamic>;
            final existToken = data['deviceToken'] as String;

            if (existToken != currentDeviceToken) {
              await _userDevices.doc(userData.uid).update({
                'deviceToken': currentDeviceToken,
              });
            }
          } else {
            final userDeviceModel = UserDevices(
              uid: userData.uid,
              deviceToken: currentDeviceToken,
              createdAt: Timestamp.now(),
            );
            await _userDevices.doc(userData.uid).set(userDeviceModel.toMap());
          }
        });
      }
    } else {
      return;
    }
  }

  // REMOVE DEVICE TOKEN WHEN USER LOGS OUT
  Future<void> removeUserDeviceToken(String uid) async {
    try {
      await _userDevices.doc(uid).delete();
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw e.toString();
    }
  }

  
}

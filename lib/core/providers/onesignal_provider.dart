import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

final oneSignalNotificationsProvider = Provider<OneSignalNotifications>((ref) {
  return OneSignal.Notifications;
});

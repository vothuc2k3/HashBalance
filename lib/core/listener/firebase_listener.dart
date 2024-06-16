import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/models/user_model.dart';

class FirestoreUserListener extends ConsumerStatefulWidget {
  const FirestoreUserListener({super.key});

  @override
  FirestoreUserListenerState createState() => FirestoreUserListenerState();
}

class FirestoreUserListenerState extends ConsumerState<FirestoreUserListener> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _subscription =
        _firestore.collection('users').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          var data = change.doc.data();
          if (data != null) {
            UserModel user = UserModel(
              email: data['email'] as String,
              name: data['name'] as String,
              uid: data['uid'] as String,
              createdAt: data['createdAt'] as Timestamp,
              profileImage: data['profileImage'] as String,
              bannerImage: data['bannerImage'] as String,
              isAuthenticated: data['isAuthenticated'] as bool,
              isRestricted: data['isRestricted'] as bool,
              activityPoint: data['activityPoint'] as int,
              achivements: List<String>.from(data['achivements']),
              friends: List<String>.from(data['friends']),
              followers: List<String>.from(data['followers']),
              notifId: List<String>.from(data['notifId']),
            );
            int hashAge = calculateHashAge(user.createdAt);
            if (user.hashAge != hashAge) {
              _firestore.collection('users').doc(user.uid).update({
                'hashAge': hashAge,
              });
            }
          }
        }
      }
    });
  }

  int calculateHashAge(Timestamp createdAt) {
    DateTime now = DateTime.now();
    DateTime createdDate = createdAt.toDate();
    Duration ageDuration = now.difference(createdDate);
    return ageDuration.inDays;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Listener Example'),
      ),
      body: const Center(
        child: Text('Listening to Firestore changes...'),
      ),
    );
  }
}

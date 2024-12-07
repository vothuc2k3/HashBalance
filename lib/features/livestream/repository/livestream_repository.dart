import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hash_balance/core/constants/firebase_constants.dart';
import 'package:hash_balance/core/failures.dart';
import 'package:hash_balance/core/providers/firebase_providers.dart';
import 'package:hash_balance/models/livestream_comment_model.dart';
import 'package:hash_balance/models/livestream_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final livestreamRepositoryProvider = Provider((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return LivestreamRepository(firestore: firestore);
});

class LivestreamRepository {
  final FirebaseFirestore _firestore;

  LivestreamRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  CollectionReference get livestreams =>
      _firestore.collection(FirebaseConstants.livestreamsCollection);

  CollectionReference get livestreamComments =>
      _firestore.collection(FirebaseConstants.livestreamCommentsCollection);

  Future<Either<Failures, void>> createLivestream(Livestream livestream) async {
    try {
      await livestreams.doc(livestream.id).set(livestream.toMap());
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<List<LivestreamComment>> getLivestreamComments(String streamId) {
    return livestreamComments
        .where('streamId', isEqualTo: streamId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((event) => event.docs
            .map((doc) =>
                LivestreamComment.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<Either<Failures, void>> createLivestreamComment(
    LivestreamComment livestreamComment,
  ) async {
    try {
      await livestreamComments
          .doc(livestreamComment.id)
          .set(livestreamComment.toMap());
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, String>> fetchAgoraToken(String channelName) async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['DOMAIN']}/access_token?channelName=$channelName'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return right(data['token']);
      } else {
        throw Exception('Failed to load token');
      }
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<Livestream?> getCommunityLivestream(String communityId) {
    return livestreams
        .where('communityId', isEqualTo: communityId)
        .where('status', isEqualTo: 'on_going')
        .snapshots()
        .map(
      (event) {
        if (event.docs.isNotEmpty) {
          return Livestream.fromMap(
              event.docs.first.data() as Map<String, dynamic>);
        } else {
          return null;
        }
      },
    );
  }

  Future<Either<Failures, void>> endLivestream(String livestreamId) async {
    try {
      await livestreams.doc(livestreamId).update({'status': 'ended'});
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<Livestream> listenToLivestream(String livestreamId) {
    return livestreams.doc(livestreamId).snapshots().map((event) => Livestream.fromMap(event.data() as Map<String, dynamic>));
  }
}

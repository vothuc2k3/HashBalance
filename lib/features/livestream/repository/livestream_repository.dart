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

  CollectionReference get _livestreams =>
      _firestore.collection(FirebaseConstants.livestreamsCollection);

  CollectionReference get _livestreamComments =>
      _firestore.collection(FirebaseConstants.livestreamCommentsCollection);

  Future<Either<Failures, void>> createLivestream(Livestream livestream) async {
    try {
      await _livestreams.doc(livestream.id).set(livestream.toMap());
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<List<LivestreamComment>> getLivestreamComments(String streamId) {
    return _livestreamComments
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
      await _livestreamComments
          .doc(livestreamComment.id)
          .set(livestreamComment.toMap());
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Future<Either<Failures, String>> fetchAgoraToken(String channelName) async {
    try {
      final response = await http.get(Uri.parse(
          '${dotenv.env['DOMAIN']}/agoraAccessToken?channelName=$channelName'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return right(data['token']);
      } else if (response.statusCode == 400) {
        throw Exception(
            'Bad Request: The server could not understand the request. Check if the channel name is provided correctly.');
      } else if (response.statusCode == 500) {
        throw Exception(
            'Server Error: Something went wrong on the server while generating the token.');
      } else {
        throw Exception('${response.statusCode}');
      }
    } catch (e) {
      return left(Failures('Error fetching Agora token: ${e.toString()}'));
    }
  }

  Stream<Livestream?> getCommunityLivestream(String communityId) {
    return _livestreams
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
      await _livestreams.doc(livestreamId).update({'status': 'ended'});
      return right(null);
    } catch (e) {
      return left(Failures(e.toString()));
    }
  }

  Stream<Livestream> listenToLivestream(String livestreamId) {
    return _livestreams.doc(livestreamId).snapshots().map(
        (event) => Livestream.fromMap(event.data() as Map<String, dynamic>));
  }

  Future<void> updateAgoraUid(String livestreamId, int agoraUid) async {
    await _livestreams.doc(livestreamId).update({'agoraUid': agoraUid});
  }
}

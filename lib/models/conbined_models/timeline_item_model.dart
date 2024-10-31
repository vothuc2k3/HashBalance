import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hash_balance/models/conbined_models/post_data_model.dart';
import 'package:hash_balance/models/conbined_models/post_share_data_model.dart';

class TimelineItem {
  final String id;
  final String uid;
  final String content;
  final Timestamp createdAt;
  final bool isShare;
  final PostDataModel? postData;
  final PostShareDataModel? postShareData;

  TimelineItem._({
    required this.id,
    required this.uid,
    required this.content,
    required this.createdAt,
    required this.isShare,
    this.postData,
    this.postShareData,
  });

  // Factory constructor cho Post
  factory TimelineItem.fromPost(PostDataModel postData) {
    return TimelineItem._(
      id: postData.post.id,
      uid: postData.post.uid,
      content: postData.post.content,
      createdAt: postData.post.createdAt,
      isShare: false,
      postData: postData,
    );
  }

  // Factory constructor cho PostShare
  factory TimelineItem.fromPostShare(PostShareDataModel postShareData) {
    return TimelineItem._(
      id: postShareData.postShare.id,
      uid: postShareData.postShare.uid,
      content: postShareData.postShare.content,
      createdAt: postShareData.postShare.createdAt,
      isShare: true,
      postShareData: postShareData,
    );
  }
}

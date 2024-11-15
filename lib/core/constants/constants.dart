import 'package:flutter/material.dart';
import 'package:hash_balance/features/community/screen/community_list_screen.dart';
import 'package:hash_balance/features/message/screen/conversations_screen.dart';
import 'package:hash_balance/features/newsfeed/screen/newsfeed_screen.dart';
import 'package:hash_balance/features/notification/screen/notification_screen.dart';
import 'package:hash_balance/features/post/screen/create_post_screen.dart';

class Constants {
  static const logoPath = 'assets/images/logo.png';
  static const signinEmotePath = 'assets/images/signinEmote.png';
  static const googleLogoPath = 'assets/images/googleLogo.png';
  static const facebookLogoPath = 'assets/images/facebookLogo.png';
  static const emailLogoPath = 'assets/images/emailLogo.png';

  static const bannerDefault =
      'https://firebasestorage.googleapis.com/v0/b/hash-balance-official-2.appspot.com/o/defaultbanner.jpeg?alt=media&token=1f1f6ff7-7344-42b8-9c69-7cfbe36165bb';
  static const cameraIcon =
      'https://firebasestorage.googleapis.com/v0/b/hash-balance-official-2.appspot.com/o/defaultcamera.png?alt=media&token=6279e21f-0d6e-4744-b689-b1d600d25f75';
  static const avatarDefault = [
    'https://firebasestorage.googleapis.com/v0/b/hash-balance-official-2.appspot.com/o/defaultavatar1.jpg?alt=media&token=0e12b61c-7b42-4e49-882c-1c398a9af543',
    'https://firebasestorage.googleapis.com/v0/b/hash-balance-official-2.appspot.com/o/defaultavatar2.jpg?alt=media&token=8fb5265b-e049-4867-94e4-ed5a1a34d887',
    'https://firebasestorage.googleapis.com/v0/b/hash-balance-official-2.appspot.com/o/defaultavatar3.jpg?alt=media&token=04299647-a572-4477-9705-25dfb0cc0595',
  ];

  static const communityTypes = ['Public', 'Restricted', 'Private'];

  static const communityTypesDescMap = {
    'Public': 'Anybody can view, post, and comment to this community',
    'Restricted':
        'Anybody can view, and comment, but ONLY users with approval can post',
    'Private': 'ONLY approved users can view and interact with this community',
  };

  static const Map<String, IconData> communityTypeIcons = {
    'Public': Icons.public,
    'Restricted': Icons.lock,
    'Private': Icons.privacy_tip,
  };

  static const String memberRole = 'member';
  static const String moderatorRole = 'moderator';

  static const tabWidgets = [
    NewsfeedScreen(),
    CommunityListScreen(),
    CreatePostScreen(),
    ConversationScreen(),
    NotificationScreen(),
  ];

  static final List<String> titles = [
    'Home',
    'Communities',
    'Create',
    'Chat',
    'Inbox'
  ];
  //MARK: - Notification Constants
  static const String friendRequestTitle = 'New Friend Request!';
  static const String acceptRequestTitle = 'Friend Request Accepted!';
  static const String newFollowerTitle = 'New Follower!';
  static const String moderatorInvitationTitle =
      'You are invited as a moderator!';
  static const String incomingCallTitle = 'Incoming Call!';
  static const String commentMentionTitle = 'Comment Mentioned!';

  //MARK: - Notification Types
  static const String friendRequestType = 'friend_request';
  static const String acceptRequestType = 'accept_request';
  static const String moderatorInvitationType = 'moderator_invitation';
  static const String incomingMessageType = 'incoming_message';
  static const String conversationInvitationType = 'conversation_invitation';
  static const String newFollowerType = 'new_follower';
  static const String incomingCallType = 'incoming_call';
  static const String userReportType = 'user_report';
  static const String postReportType = 'post_report';
  static const String commentReportType = 'comment_report';
  static const String commentMentionType = 'comment_mention';

  //MARK: - Call Status
  static const String callStatusDialling = 'dialling';
  static const String callStatusOngoing = 'on_going';
  static const String callStatusEnded = 'ended';
  static const String callStatusMissed = 'missed';
  static const String callStatusDeclined = 'declined';

  //MARK: - Member Status
  static const String memberActiveStatus = 'active';
  static const String memberInactiveStatus = 'inactive';
  static const String memberBannedStatus = 'banned';

  //MARK: - Friend Request Status
  static const String friendRequestStatusPending = 'pending';
  static const String friendRequestStatusAccepted = 'accepted';
  static const String friendRequestStatusDeclined = 'declined';

  //MARK: - Activity Log Types
  static const String activityLogTypeFriendRequest = 'friend_request';
  static const String activityLogTypeAcceptRequest = 'accept_request';
  static const String activityLogTypeNewFollowing = 'new_following';
  static const String activityLogTypeNewFollower = 'new_follower';
  static const String activityLogTypePost = 'post';
  static const String activityLogTypeComment = 'comment';
  static const String activityLogTypeUpvote = 'upvote';
  static const String activityLogTypeDownvote = 'downvote';
  static const String activityLogTypeJoinCommunity = 'join_community';
  static const String activityLogTypeLeaveCommunity = 'leave_community';
  static const String activityLogTypeDeletePost = 'delete_post';
  static const String activityLogTypeDeleteComment = 'delete_comment';

  static const String activityLogTypeDeleteJoinCommunity =
      'delete_join_community';
  static const String activityLogTypeDeleteLeaveCommunity =
      'delete_leave_community';

  static String getFriendRequestContent(String name) {
    return '$name has sent you a friend request!';
  }

  static String getAcceptRequestContent(String name) {
    return '$name has accepted your friend request!';
  }

  static String getModeratorInvitationContent(
      String name, String communityName) {
    return '$name has invited you as a moderator of $communityName!';
  }

  static String getIncomingCallContent(String name) {
    return '$name is calling....';
  }

  static String getNewFollowerContent(String name) {
    return '$name has followed you!';
  }

  static String getCommentMentionContent(String name) {
    return '$name has mentioned you in a comment!';
  }

  static String getActivityLogUpvoteMessage({
    required String postAuthorName,
    required String communityName,
  }) {
    return 'You have upvoted a post in $communityName by $postAuthorName.';
  }

  static String getActivityLogDownvoteMessage({
    required String postAuthorName,
    required String communityName,
  }) {
    return 'You have downvoted a post in $communityName by $postAuthorName.';
  }

  static String agoraAppId = 'a9942d0368fc4cdf9e59df9df19899c9';

  static String domain = 'https://web-production-f331.up.railway.app';
}

import 'package:flutter/material.dart';
import 'package:hash_balance/features/community/screen/community_list_screen.dart';
import 'package:hash_balance/features/message/screen/message_list_screen.dart';
import 'package:hash_balance/features/newsfeed/screen/newsfeed_screen.dart';
import 'package:hash_balance/features/notification/screen/notification_screen.dart';
import 'package:hash_balance/features/post/screen/create_post_screen.dart';

class Constants {
  static const logoPath = 'assets/images/logo.png';
  static const signinEmotePath = 'assets/images/signinEmote.png';
  static const googleLogoPath = 'assets/images/googleLogo.png';
  static const facebookLogoPath = 'assets/images/facebookLogo.png';
  static const emailLogoPath = 'assets/images/emailLogo.png';

  static const bannerDefault = 'https://i.imgur.com/gKLRsMZ.jpg';
  static const cameraIcon = 'https://i.imgur.com/cqjP4oR.png';
  static const avatarDefault = [
    'https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/avatars/89/89496ab402ac222c0ddaed7add5d9eb6deb759f9_full.jpg',
    'https://ichef.bbci.co.uk/news/976/cpsprodpb/16620/production/_91408619_55df76d5-2245-41c1-8031-07a4da3f313f.jpg',
    'https://media.vanityfair.com/photos/5f5156490ca7fe28f9ec3f55/4:3/w_1775,h_1331,c_limit/feels-good-man-film.jpg'
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
    MessageListScreen(),
    NotificationScreen(),
  ];

  static final List<String> titles = [
    'Home',
    'Communities',
    'Create',
    'Chat',
    'Inbox'
  ];
  static const String friendRequestTitle = 'New Friend Request';
  static const String acceptRequestTitle = 'Friend Request Accepted';
  static const String incomingMessageTitle = 'New Message!';

  static const String friendRequestType = 'friend_request';
  static const String acceptRequestType = 'accept_request';

  static String getFriendRequestContent(String name) {
    return '$name has sent you a friend request!';
  }

  static String getAcceptRequestContent(String name) {
    return '$name has accepted your friend request!';
  }

  static String getIncomingMessageContent(String name) {
    return '$name has sent you a message!';
  }

  static String? deviceToken;

  static String agoraAppId = 'a9942d0368fc4cdf9e59df9df19899c9';

  static String domain = 'https://web-production-f331.up.railway.app';
}

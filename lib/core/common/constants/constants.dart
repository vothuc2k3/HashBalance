import 'package:flutter/material.dart';
import 'package:hash_balance/features/community/screen/community_list_screen.dart';
import 'package:hash_balance/features/message/screen/message_list_screen.dart';
import 'package:hash_balance/features/newsfeed/screen/newsfeed_screen.dart';
import 'package:hash_balance/features/notification/screen/notification_screen.dart';
import 'package:hash_balance/features/post/screen/create_post/create_post_screen.dart';

class Constants {
  static const logoPath = 'assets/images/logo.png';
  static const signinEmotePath = 'assets/images/signinEmote.png';
  static const googleLogoPath = 'assets/images/googleLogo.png';
  static const facebookLogoPath = 'assets/images/facebookLogo.png';
  static const emailLogoPath = 'assets/images/emailLogo.png';

  static const bannerDefault = 'https://i.imgur.com/gKLRsMZ.jpg';
  static const cameraIcon = 'https://i.imgur.com/cqjP4oR.png';
  static const avatarDefault =
      'https://cdn.cloudflare.steamstatic.com/steamcommunity/public/images/avatars/89/89496ab402ac222c0ddaed7add5d9eb6deb759f9_full.jpg';

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

  static String getFriendRequestContent(String name) {
    return '$name has sent you a friend request!';
  }

  static const String requestAcceptedTitle = 'Friend Request Accepted';
}

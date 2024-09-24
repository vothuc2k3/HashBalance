import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/user_model.dart';

class MentionAutocompleteOptions extends ConsumerWidget {
  final String query;
  final Function(UserModel) onMentionUserTap;

  final List<UserModel>? friends = Constants.friends;

  MentionAutocompleteOptions({
    super.key,
    required this.query,
    required this.onMentionUserTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<UserModel> filteredUsers = friends!.where((user) {
      return user.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
    if (filteredUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: ref.watch(preferredThemeProvider).first,
      elevation: 4.0,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(user.profileImage),
            ),
            title: Text(user.name),
            onTap: () => onMentionUserTap(user),
          );
        },
      ),
    );
  }
}

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/livestream/controller/livestream_controller.dart';
import 'package:hash_balance/features/livestream/screen/audience_livestream_screen.dart';
import 'package:hash_balance/models/livestream_model.dart';

class CommunityLivestreamContainer extends ConsumerStatefulWidget {
  final Livestream livestream;
  final String communityName;

  const CommunityLivestreamContainer({
    super.key,
    required this.livestream,
    required this.communityName,
  });

  @override
  ConsumerState<CommunityLivestreamContainer> createState() =>
      _CommunityLivestreamContainerState();
}

class _CommunityLivestreamContainerState
    extends ConsumerState<CommunityLivestreamContainer> {
  _joinLivestream(BuildContext context, String currentUid) async {
    await ref
        .read(livestreamControllerProvider)
        .updateAgoraUid(widget.livestream.id, widget.livestream.agoraUid + 1);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudienceLivestreamScreen(
          livestream: widget.livestream,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider)!;
    return GestureDetector(
      onTap: () => _joinLivestream(context, currentUser.uid),
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.livestream.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap to join the livestream',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

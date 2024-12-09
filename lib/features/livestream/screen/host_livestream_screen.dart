// ignore_for_file: use_build_context_synchronously

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:hash_balance/features/livestream/controller/livestream_controller.dart';
import 'package:hash_balance/models/livestream_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HostLivestreamScreen extends ConsumerStatefulWidget {
  final Livestream livestream;

  const HostLivestreamScreen({
    super.key,
    required this.livestream,
  });

  @override
  HostLivestreamScreenState createState() => HostLivestreamScreenState();
}

class HostLivestreamScreenState extends ConsumerState<HostLivestreamScreen> {
  late final AgoraClient agoraClient;

  @override
  void initState() {
    super.initState();
    _setupAgoraClient();
    _initializeAgora();
  }

  void _setupAgoraClient() {
    final appId = dotenv.env['AGORA_APP_ID'];
    if (appId == null || appId.isEmpty) {
      throw Exception('AGORA_APP_ID is not set in the environment variables.');
    }

    agoraClient = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
        appId: appId,
        channelName: widget.livestream.communityId,
        tempToken: widget.livestream.agoraToken!,
        uid: widget.livestream.agoraUid,
      ),
      agoraChannelData: AgoraChannelData(
        channelProfileType: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> _initializeAgora() async {
    try {
      await agoraClient.initialize();
      await agoraClient.engine.joinChannel(
        token: widget.livestream.agoraToken!,
        channelId: widget.livestream.id,
        uid: widget.livestream.agoraUid,
        options: const ChannelMediaOptions(
          autoSubscribeAudio: false,
          autoSubscribeVideo: false,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );
    } catch (e) {
      // Handle initialization errors
      debugPrint('Error initializing Agora: $e');
    }
  }

  Future<void> _endLivestream() async {
    try {
      await ref
          .read(livestreamControllerProvider)
          .endLivestream(widget.livestream.id);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error ending livestream: $e');
    }
  }

  @override
  void dispose() {
    agoraClient.engine.leaveChannel();
    agoraClient.engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Host Livestream"),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end),
            onPressed: _endLivestream,
          ),
        ],
      ),
      body: Stack(
        children: [
          AgoraVideoViewer(
            client: agoraClient,
            showNumberOfUsers: true,
            layoutType: Layout.grid,
          ),
          AgoraVideoButtons(
            client: agoraClient,
            disconnectButtonChild: IconButton(
              icon: const Icon(Icons.call_end),
              onPressed: _endLivestream,
            ),
          ),
        ],
      ),
    );
  }
}

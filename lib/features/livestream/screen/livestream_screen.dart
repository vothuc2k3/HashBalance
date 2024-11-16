// ignore_for_file: use_build_context_synchronously

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/features/livestream/controller/livestream_controller.dart';
import 'package:hash_balance/features/livestream/screen/widget/live_comment_box.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/livestream_model.dart';
import 'package:logger/logger.dart';

class LivestreamScreen extends ConsumerStatefulWidget {
  final Livestream livestream;
  final String uid;
  final bool isHost;

  LivestreamScreen({
    required this.livestream,
    required this.uid,
    super.key,
  }) : isHost = livestream.uid == uid;

  @override
  LivestreamScreenState createState() => LivestreamScreenState();
}

class LivestreamScreenState extends ConsumerState<LivestreamScreen> {
  late AgoraClient agoraClient;
  bool isScreenPopped = false;

  @override
  void initState() {
    initializeAgoraClient();
    super.initState();
  }

  Future<void> initializeAgoraClient() async {
    if (widget.isHost) {
      await [Permission.camera, Permission.microphone].request();
    }
    agoraClient = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
        appId: Constants.agoraAppId,
        channelName: widget.livestream.id,
        tempToken: widget.livestream.agoraToken!,
      ),
    );
    await agoraClient.initialize();
    ChannelMediaOptions options = ChannelMediaOptions(
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      clientRoleType: widget.isHost
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
      publishCameraTrack: widget.isHost,
      publishMicrophoneTrack: widget.isHost,
      autoSubscribeAudio: true,
      autoSubscribeVideo: true,
    );
    await agoraClient.engine.joinChannel(
      token: widget.livestream.agoraToken!,
      channelId: widget.livestream.id,
      uid: 0,
      options: options,
    );
    Logger()
        .d('Joined channel with role: ${widget.isHost ? 'Host' : 'Audience'}');
  }

  Future<void> onEndLivestream() async {
    if (widget.isHost) {
      await ref
          .read(livestreamControllerProvider)
          .endLivestream(widget.livestream.id);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    agoraClient.sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Livestream?>>(
      listenToLivestreamProvider(widget.livestream.id),
      (previous, next) {
        next.when(
          data: (livestream) {
            if (livestream == null ||
                livestream.status != Constants.callStatusOngoing) {
              if (!isScreenPopped) {
                isScreenPopped = true;
                Navigator.pop(context);
              }
            }
          },
          error: (_, __) {},
          loading: () {},
        );
      },
    );

    return Scaffold(
      backgroundColor: ref.watch(preferredThemeProvider).first,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            await agoraClient.engine.leaveChannel();
            await onEndLivestream();
          },
        ),
      ),
      body: Stack(
        children: [
          AgoraVideoViewer(
            client: agoraClient,
            showNumberOfUsers: true,
            renderModeType: RenderModeType.renderModeAdaptive,
          ),
          if (widget.isHost)
            AgoraVideoButtons(
              client: agoraClient,
              disconnectButtonChild: IconButton(
                onPressed: () async {
                  await agoraClient.engine.leaveChannel();
                  await onEndLivestream();
                },
                icon: const Icon(Icons.call_end),
              ),
            ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color:
                      ref.watch(preferredThemeProvider).second.withOpacity(0.1),
                ),
                width: MediaQuery.of(context).size.width * 0.3,
                height: MediaQuery.of(context).size.height * 0.6,
                child: LiveCommentBox(streamId: widget.livestream.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

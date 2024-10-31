// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/features/livestream/screen/widget/live_comment_box.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/livestream_model.dart';
import 'package:logger/logger.dart';

class LivestreamScreen extends ConsumerStatefulWidget {
  final Livestream livestream;
  final bool isHost;

  const LivestreamScreen({
    super.key,
    required this.livestream,
    required this.isHost,
  });

  @override
  LivestreamScreenState createState() => LivestreamScreenState();
}

class LivestreamScreenState extends ConsumerState<LivestreamScreen> {
  late RtcEngine _engine;
  bool _isMicOn = true;
  bool _isCameraOn = true;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
  }

  Future<void> _initializeAgora() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      RtcEngineContext(
        appId: Constants.agoraAppId,
      ),
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          Logger().d('Joined channel: ${connection.channelId}');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          Logger().d('User joined: $remoteUid');
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          Logger().d('User offline: $remoteUid');
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 1280, height: 720),
        frameRate: 60,
      ),
    );

    await _engine.joinChannel(
      token: widget.livestream.agoraToken!,
      channelId: widget.livestream.id,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: widget.isHost
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );
  }

  void _toggleMic() {
    setState(() {
      _isMicOn = !_isMicOn;
      _engine.muteLocalAudioStream(!_isMicOn);
    });
  }

  void _toggleCamera() {
    setState(() {
      _isCameraOn = !_isCameraOn;
      _engine.muteLocalVideoStream(!_isCameraOn);
    });
  }

  Future<void> _onEndLivestream() async {
    await _engine.leaveChannel();
    await _engine.release();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ref.watch(preferredThemeProvider).first,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _onEndLivestream,
        ),
      ),
      body: Stack(
        children: [
          AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _isMicOn ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _toggleMic,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: Icon(
                      _isCameraOn ? Icons.videocam : Icons.videocam_off,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: _toggleCamera,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(
                      Icons.call_end,
                      color: Colors.red,
                      size: 30,
                    ),
                    onPressed: _onEndLivestream,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: ref.watch(preferredThemeProvider).second,
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

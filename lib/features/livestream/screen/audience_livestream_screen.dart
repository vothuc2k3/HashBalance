import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/livestream/screen/widget/live_comment_box.dart';
import 'package:hash_balance/models/livestream_model.dart';

class AudienceLivestreamScreen extends ConsumerStatefulWidget {
  final Livestream livestream;

  const AudienceLivestreamScreen({
    super.key,
    required this.livestream,
  });

  @override
  AudienceLivestreamScreenState createState() =>
      AudienceLivestreamScreenState();
}

class AudienceLivestreamScreenState
    extends ConsumerState<AudienceLivestreamScreen> {
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
        clientRoleType: ClientRoleType.clientRoleAudience,
      ),
    );
  }

  Future<void> _initializeAgora() async {
    try {
      await agoraClient.initialize();

      await agoraClient.engine.enableVideo();
      await agoraClient.engine.enableLocalVideo(false);

      await agoraClient.engine.joinChannel(
        token: widget.livestream.agoraToken!,
        channelId: widget.livestream.id,
        uid: widget.livestream.agoraUid,
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: false,
          publishMicrophoneTrack: false,
          publishScreenTrack: false,
          publishScreenCaptureAudio: false,
          publishScreenCaptureVideo: false,
          clientRoleType: ClientRoleType.clientRoleAudience,
        ),
      );
    } catch (e) {
      debugPrint('Error initializing Agora: $e');
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
        title: const Text("Audience Livestream"),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          AgoraVideoViewer(
            client: agoraClient,
            showNumberOfUsers: true,
            layoutType: Layout.grid,
            enableHostControls: false,
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.withOpacity(0.1),
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

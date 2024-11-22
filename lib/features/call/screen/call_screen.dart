import 'package:agora_uikit/agora_uikit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/call/controller/call_controller.dart';
import 'package:hash_balance/models/call_model.dart';
import 'package:hash_balance/models/user_model.dart';

class CallScreen extends ConsumerStatefulWidget {
  final Call _call;
  final UserModel _caller;
  final UserModel _receiver;
  final String _token;

  const CallScreen({
    super.key,
    required Call call,
    required UserModel caller,
    required UserModel receiver,
    required String token,
  })  : _call = call,
        _caller = caller,
        _receiver = receiver,
        _token = token;

  @override
  CallScreenState createState() => CallScreenState();
}

class CallScreenState extends ConsumerState<CallScreen> {
  late String channelName;
  AgoraClient? agoraClient;
  bool _isScreenPopped = false;

  Future<void> _onEndCall() async {
    await ref.read(callControllerProvider.notifier).endCall(widget._call);
  }

  @override
  void dispose() {
    agoraClient?.engine.release();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    channelName = getUids(widget._caller.uid, widget._receiver.uid);
    agoraClient = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
        appId: Constants.agoraAppId,
        channelName: channelName,
        tempToken: widget._token,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initAgora();
  }

  Future<void> initAgora() async {
    await agoraClient!.initialize();

    agoraClient!.engine.setChannelProfile(
      ChannelProfileType.channelProfileCommunication,
    );

    // Đồng bộ trạng thái ban đầu
    agoraClient!.sessionController.value =
        agoraClient!.sessionController.value.copyWith(
      isLocalUserMuted: false,
      isLocalVideoDisabled: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Call?>>(
      listenToCallProvider(widget._call.id),
      (previous, next) {
        next.when(
          data: (call) {
            if (call == null || call.status != Constants.callStatusOngoing) {
              if (!_isScreenPopped) {
                _isScreenPopped = true;
                Navigator.pop(context);
              }
            }
          },
          error: (_, __) {},
          loading: () {},
        );
      },
    );

    final isLocalVideoDisabled =
        agoraClient?.sessionController.value.isLocalVideoDisabled ?? true;
    final isRemoteVideoDisabled =
        agoraClient?.sessionController.value.users.every(
              (user) => user.videoDisabled,
            ) ??
            true;

    return Scaffold(
      body: agoraClient == null
          ? const Loading()
          : SafeArea(
              child: Stack(
                children: [
                  if (isLocalVideoDisabled && isRemoteVideoDisabled)
                    _buildBothCamerasDisabledView(),
                  if (!isLocalVideoDisabled && !isRemoteVideoDisabled)
                    AgoraVideoViewer(client: agoraClient!),
                  if (isLocalVideoDisabled && !isRemoteVideoDisabled)
                    _buildSingleUserDisabledView(
                      avatar: widget._caller.profileImage,
                      name: widget._caller.name,
                      message: "Your camera is disabled",
                    ),
                  if (!isLocalVideoDisabled && isRemoteVideoDisabled)
                    _buildSingleUserDisabledView(
                      avatar: widget._receiver.profileImage,
                      name: widget._receiver.name,
                      message: "Receiver's camera is disabled",
                    ),
                  // Action Buttons
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: agoraClient!
                                  .sessionController.value.isLocalUserMuted
                              ? Icons.mic_off
                              : Icons.mic,
                          color: agoraClient!
                                  .sessionController.value.isLocalUserMuted
                              ? Colors.red
                              : Colors.green,
                          onPressed: () {
                            final isMuted = agoraClient!
                                .sessionController.value.isLocalUserMuted;
                            agoraClient!.engine.muteLocalAudioStream(!isMuted);
                            agoraClient!.sessionController.updateUserAudio(
                              uid:
                                  agoraClient!.sessionController.value.localUid,
                              muted: !isMuted,
                            );
                            setState(() {});
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.call_end,
                          color: Colors.redAccent,
                          onPressed: () async {
                            await agoraClient!.engine.leaveChannel();
                            await _onEndCall();
                          },
                        ),
                        _buildActionButton(
                          icon: agoraClient!
                                  .sessionController.value.isLocalVideoDisabled
                              ? Icons.videocam_off
                              : Icons.videocam,
                          color: agoraClient!
                                  .sessionController.value.isLocalVideoDisabled
                              ? Colors.blue
                              : Colors.green,
                          onPressed: () {
                            final isVideoDisabled = agoraClient!
                                .sessionController.value.isLocalVideoDisabled;

                            agoraClient!.engine
                                .muteLocalVideoStream(!isVideoDisabled);
                            agoraClient!.sessionController.updateUserVideo(
                              uid:
                                  agoraClient!.sessionController.value.localUid,
                              videoDisabled: !isVideoDisabled,
                            );

                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBothCamerasDisabledView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 70,
            backgroundImage:
                CachedNetworkImageProvider(widget._caller.profileImage),
          ),
          const SizedBox(height: 10),
          Text(
            widget._caller.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Both Cameras Disabled",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 30),
          CircleAvatar(
            radius: 70,
            backgroundImage:
                CachedNetworkImageProvider(widget._receiver.profileImage),
          ),
          const SizedBox(height: 10),
          Text(
            widget._receiver.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleUserDisabledView({
    required String avatar,
    required String name,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 70,
            backgroundImage: CachedNetworkImageProvider(avatar),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.8),
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}

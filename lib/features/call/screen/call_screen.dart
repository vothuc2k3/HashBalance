import 'package:agora_uikit/agora_uikit.dart';
import 'package:agora_uikit/controllers/rtc_buttons.dart';
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
    channelName = getUids(
      widget._caller.uid,
      widget._receiver.uid,
    );
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

  void initAgora() async {
    await agoraClient!.initialize();
    agoraClient!.engine.setChannelProfile(
      ChannelProfileType.channelProfileCommunication,
    );
    toggleCamera(sessionController: agoraClient!.sessionController);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Call?>>(
      listenToCallProvider(widget._call.id),
      (previous, next) {
        next.when(
          data: (call) {
            if (call == null) {
              if (!_isScreenPopped) {
                _isScreenPopped = true;
                Navigator.pop(context);
              }
            } else {
              if (call.status != Constants.callStatusOngoing) {
                if (!_isScreenPopped) {
                  _isScreenPopped = true;
                  Navigator.pop(context);
                }
              }
            }
          },
          error: (_, __) {},
          loading: () {},
        );
      },
    );
    return Scaffold(
      body: agoraClient == null
          ? const Loading()
          : SafeArea(
              child: Stack(
                children: [
                  if (agoraClient!.sessionController.value.isLocalVideoDisabled)
                    Center(
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: CachedNetworkImageProvider(
                          widget._caller.profileImage,
                        ),
                      ),
                    )
                  else
                    AgoraVideoViewer(client: agoraClient!),
                  Positioned(
                    bottom: 50,
                    right: 50,
                    child: agoraClient!
                            .sessionController.value.isLocalVideoDisabled
                        ? CircleAvatar(
                            radius: 60,
                            backgroundImage: CachedNetworkImageProvider(
                              widget._receiver.profileImage,
                            ),
                          )
                        : Container(),
                  ),
                  AgoraVideoButtons(
                    client: agoraClient!,
                    disconnectButtonChild: IconButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await agoraClient!.engine.leaveChannel();
                        await _onEndCall();
                      },
                      icon: const Icon(Icons.call_end),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

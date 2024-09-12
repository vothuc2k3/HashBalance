// ignore_for_file: use_build_context_synchronously

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/models/user_model.dart';

class CallScreen extends ConsumerStatefulWidget {
  final UserModel _caller;
  final UserModel _receiver;
  final String _token;

  const CallScreen({
    super.key,
    required UserModel caller,
    required UserModel receiver,
    required String token,
  })  : _caller = caller,
        _receiver = receiver,
        _token = token;

  @override
  CallScreenState createState() => CallScreenState();
}

class CallScreenState extends ConsumerState<CallScreen> {
  bool muted = false;
  late String channelName;
  AgoraClient? agoraClient;

  void _onEndCall() {
    agoraClient?.engine.leaveChannel();
    Navigator.pop(context);
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
    agoraClient!.engine.registerEventHandler(
      RtcEngineEventHandler(
        onLeaveChannel: (connection, stats) {
          showToast(false, 'Leave call');
          _onEndCall();
        },
        onUserOffline: (connection, uid, reason) {
          showToast(false, 'User offline');
          _onEndCall();
        },
        onConnectionLost: (connection) {
          showToast(false, 'Connection lost');
          _onEndCall();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: agoraClient == null
          ? const Loading()
          : SafeArea(
              child: Stack(
                children: [
                  AgoraVideoViewer(client: agoraClient!),
                  AgoraVideoButtons(
                    client: agoraClient!,
                    disconnectButtonChild: IconButton(
                      onPressed: () async {
                        await agoraClient!.engine.leaveChannel();
                        Navigator.pop(context);
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

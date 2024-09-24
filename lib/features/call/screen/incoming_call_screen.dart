import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/call/controller/call_controller.dart';
import 'package:hash_balance/features/call/screen/call_screen.dart';
import 'package:hash_balance/features/home/screen/home_screen.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/call_model.dart';
import 'package:hash_balance/models/conbined_models/call_data_model.dart';
import 'package:just_audio/just_audio.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({
    super.key,
    required CallDataModel callData,
  }) : _callData = callData;

  final CallDataModel _callData;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  bool _isScreenPopped = false;
  late AudioPlayer _audioPlayer;

  void _onAcceptCall() async {
    final result = await ref
        .read(callControllerProvider.notifier)
        .acceptCall(widget._callData.call);
    result.fold(
      (l) {
        showToast(false, l.message);
        Navigator.pop(context);
      },
      (_) {},
    );
  }

  void _onDeclineCall() async {
    final result = await ref
        .watch(callControllerProvider.notifier)
        .declineCall(widget._callData.call);
    result.fold(
      (l) {
        showToast(false, l.message);
        Navigator.pop(context);
      },
      (_) {},
    );
  }

  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setAsset('assets/audio/ringtone.mp3');
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
    } catch (e) {
      showToast(false, 'Error playing ringtone: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playRingtone();
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Call?>>(
      listenToCallProvider(widget._callData.call.id),
      (previous, next) {
        next.when(
          data: (call) {
            if (call == null) {
              // Cuộc gọi đã kết thúc hoặc không còn cuộc gọi nào
              if (!_isScreenPopped) {
                _isScreenPopped = true;
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                    ),
                  );
                }
              }
            } else {
              if (call.status == Constants.callStatusOngoing) {
                // Cuộc gọi đang diễn ra
                if (!_isScreenPopped) {
                  _isScreenPopped = true;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CallScreen(
                        call: call,
                        caller: widget._callData.caller,
                        receiver: widget._callData.receiver,
                        token: call.agoraToken!,
                      ),
                    ),
                  );
                }
              } else if (call.status != Constants.callStatusDialling) {
                if (!_isScreenPopped) {
                  _isScreenPopped = true;
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  }
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
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          color: ref.watch(preferredThemeProvider).first,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(height: 50),
            CircleAvatar(
              radius: 50,
              backgroundImage: CachedNetworkImageProvider(
                widget._callData.caller.profileImage,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget._callData.caller.name,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Audio call from Hash Balance',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FloatingActionButton(
                  heroTag: 'decline_call',
                  backgroundColor: Colors.red,
                  onPressed: () {
                    _onDeclineCall();
                  },
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: 'accept_call',
                  backgroundColor: Colors.green,
                  onPressed: () {
                    _onAcceptCall();
                  },
                  child: const Icon(Icons.call, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

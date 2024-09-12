import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/call/controller/call_controller.dart';
import 'package:hash_balance/features/call/screen/call_screen.dart';
import 'package:hash_balance/models/call_model.dart';
import 'package:hash_balance/models/conbined_models/call_data_model.dart';

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

  void _onStartCall() async {
    final result = await ref
        .read(callControllerProvider.notifier)
        .joinCall(widget._callData.call);
    result.fold(
      (l) {
        showToast(false, l.message);
        Navigator.pop(context);
      },
      (r) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(
              caller: widget._callData.caller,
              receiver: widget._callData.receiver,
              token: widget._callData.call.agoraToken!,
            ),
          ),
        );
      },
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
      (r) {
        Navigator.pop(context);
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Call?>>(
      listenToCallProvider(widget._callData.call.id),
      (previous, next) {
        next.when(
          data: (call) {
            if (call == null || call.status != Constants.callStatusDialling) {
              if (!_isScreenPopped) {
                _isScreenPopped = true;
                Navigator.pop(context);
              }
            }
          },
          error: (error, stack) {
            return const SizedBox.shrink();
          },
          loading: () {
            return const SizedBox.shrink();
          },
        );
      },
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF232845),
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
                    _onStartCall();
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

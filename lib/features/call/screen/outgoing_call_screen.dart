import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/constants/constants.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/call/controller/call_controller.dart';
import 'package:hash_balance/features/call/screen/call_screen.dart';
import 'package:hash_balance/models/conbined_models/call_data_model.dart';

class OutgoingCallScreen extends ConsumerStatefulWidget {
  const OutgoingCallScreen({
    super.key,
    required CallDataModel callData,
  }) : _callData = callData;

  final CallDataModel _callData;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends ConsumerState<OutgoingCallScreen> {
  late final Timer _timer;
  late int _timeLeft;

  void _navigateToCallScreen(String token) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          caller: widget._callData.caller,
          receiver: widget._callData.receiver,
          token: token,
        ),
      ),
    );
  }

  // Huỷ cuộc gọi nếu người gọi bấm cancel
  void _onCancelCall() async {
    final result = await ref
        .read(callControllerProvider.notifier)
        .cancelCall(widget._callData.call);

    result.fold(
      (l) => showToast(false, l.message),
      (r) {
        Navigator.pop(context);
        showToast(true, 'Call cancelled');
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _timeLeft = 30;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        setState(() {
          _timeLeft--;
          if (_timeLeft <= 0) {
            _timer.cancel();
            _onCancelCall();
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe sự thay đổi của cuộc gọi
    ref.listen<AsyncValue<CallDataModel>>(callControllerProvider,
        (previous, next) {
      next.when(
        data: (callData) {
          if (callData.call.status == Constants.callStatusOngoing) {
            _navigateToCallScreen(callData.call.agoraToken!);
          }
        },
        error: (err, stack) {
          // Xử lý lỗi nếu có
          showToast(false, 'Error: $err');
        },
        loading: () {
          // Hiển thị loading nếu cần
        },
      );
    });

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
                widget._callData.receiver.profileImage,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget._callData.receiver.name,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Waiting for answer...$_timeLeft',
              style: const TextStyle(
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
                    _onCancelCall();
                  },
                  child: const Icon(Icons.call_end, color: Colors.white),
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

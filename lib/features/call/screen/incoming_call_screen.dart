import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/call/controller/voice_call_controller.dart';
import 'package:hash_balance/models/user_model.dart';
import 'package:permission_handler/permission_handler.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  final UserModel _caller;
  final UserModel _receiver;

  const IncomingCallScreen({
    super.key,
    required UserModel caller,
    required UserModel receiver,
  })  : _caller = caller,
        _receiver = receiver;

  @override
  IncomingCallScreenState createState() => IncomingCallScreenState();
}

class IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  String? token;
  String? uids;
  String? channelName;

  void declineCall(context) {
    Navigator.pop(context);
  }

  void initCall() async {
    final voiceCallController = ref.watch(voiceCallControllerProvider.notifier);

    uids = getUids(widget._caller.uid, widget._receiver.uid);

    final fetchTokenResult = await voiceCallController.fetchAgoraToken(uids!);
    channelName = uids;
    fetchTokenResult.fold((l) {
      showToast(false, l.message);
      return;
    }, (r) => token = r);

    await Permission.camera.request();
    await Permission.microphone.request();

    final notifyCallResult =
        await voiceCallController.notifyIncomingCall(widget._receiver);
    notifyCallResult.fold(
      (l) => showToast(false, l.message),
      (_) {},
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.pinkAccent.shade100,
  //     body: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         CircleAvatar(
  //           radius: 60,
  //           backgroundImage:
  //               CachedNetworkImageProvider(widget._caller.profileImage),
  //         ),
  //         const SizedBox(height: 20),
  //         Text(
  //           '#${widget._caller.name}',
  //           style: const TextStyle(
  //             fontSize: 24,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.white,
  //           ),
  //         ),
  //         const SizedBox(height: 10),
  //         const Text(
  //           'Audio call',
  //           style: TextStyle(
  //             fontSize: 16,
  //             color: Colors.white70,
  //           ),
  //         ),
  //         const SizedBox(height: 40),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceAround,
  //           children: [
  //             Column(
  //               children: [
  //                 ElevatedButton(
  //                   onPressed: () => declineCall(context),
  //                   style: ElevatedButton.styleFrom(
  //                     shape: const CircleBorder(),
  //                     backgroundColor: Colors.redAccent,
  //                     padding: const EdgeInsets.all(20), // Background color
  //                   ),
  //                   child: const Icon(Icons.call_end,
  //                       size: 30, color: Colors.white),
  //                 ),
  //                 const SizedBox(height: 10),
  //                 const Text('Decline', style: TextStyle(color: Colors.white)),
  //               ],
  //             ),
  //             Column(
  //               children: [
  //                 ElevatedButton(
  //                   onPressed: () {
  //                     // Handle call answer action
  //                   },
  //                   style: ElevatedButton.styleFrom(
  //                     shape: const CircleBorder(),
  //                     backgroundColor: Colors.green,
  //                     padding: const EdgeInsets.all(20), // Background color
  //                   ),
  //                   child:
  //                       const Icon(Icons.call, size: 30, color: Colors.white),
  //                 ),
  //                 const SizedBox(height: 10),
  //                 const Text('Answer', style: TextStyle(color: Colors.white)),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade700,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Lê Thành Ngoan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              // Handle add friend action
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Handle more actions
            },
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundImage: CachedNetworkImageProvider(
                'https://scontent.fvca1-4.fna.fbcdn.net/v/t39.30808-6/449445386_1989980414752669_1029116083813691957_n.jpg?_nc_cat=108&ccb=1-7&_nc_sid=6ee11a&_nc_eui2=AeHD6GOjOgZR2VaqS5KTKr9rFLp04Y0m3UwUunThjSbdTK99-auu8xa1Ne5Qo87R-kaWjP1dfQwj6rTeQ4aOgcqA&_nc_ohc=jKRBENCrU7cQ7kNvgGQZOnn&_nc_ht=scontent.fvca1-4.fna&oh=00_AYCoz8r19gP28Ar3yFsbQrpa2-v3o8WLdUkoqsUTzOZ6Wg&oe=66AD3163'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Lê Thành Ngoan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Calling...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.videocam, color: Colors.white),
                onPressed: () {
                  // Handle video call toggle
                },
              ),
              IconButton(
                icon: const Icon(Icons.mic, color: Colors.white),
                onPressed: initCall,
              ),
              IconButton(
                icon: const Icon(Icons.games, color: Colors.white),
                onPressed: () {
                  // Handle gaming
                },
              ),
              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.white),
                onPressed: () {
                  // Handle speakerphone toggle
                },
              ),
              IconButton(
                icon: const Icon(Icons.call_end, color: Colors.redAccent),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

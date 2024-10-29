import 'package:flutter/material.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:appinio_video_player/appinio_video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoController;
  late CustomVideoPlayerController _customVideoPlayerController;

  @override
  void initState() {
    super.initState();

    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          ..initialize().then((_) {
            setState(() {});
          });

    _customVideoPlayerController = CustomVideoPlayerController(
      context: context,
      videoPlayerController: _videoController,
      customVideoPlayerSettings: const CustomVideoPlayerSettings(),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _customVideoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _videoController.value.isInitialized
          ? LayoutBuilder(
              builder: (context, constraints) {
                final videoAspectRatio = _videoController.value.aspectRatio;
                final screenWidth = constraints.maxWidth;
                final videoHeight = screenWidth / videoAspectRatio;
                final maxHeight = MediaQuery.of(context).size.height * 0.6;
                final finalHeight =
                    videoHeight > maxHeight ? maxHeight : videoHeight;

                return Center(
                  child: AspectRatio(
                    aspectRatio: videoAspectRatio,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: finalHeight),
                      child: CustomVideoPlayer(
                        customVideoPlayerController:
                            _customVideoPlayerController,
                      ),
                    ),
                  ),
                );
              },
            )
          : const Loading(),
    );
  }
}

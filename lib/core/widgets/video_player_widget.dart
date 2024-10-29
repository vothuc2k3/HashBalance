import 'package:flutter/material.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:video_player/video_player.dart';

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
  bool _isPlaying = false;
  String? _currentPosition;
  String? _videoDuration;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          ..initialize().then((_) {
            setState(() {
              _videoDuration = _formatDuration(_videoController.value.duration);
            });
          });

    _videoController.addListener(() {
      final isPlaying = _videoController.value.isPlaying;
      setState(() {
        _isPlaying = isPlaying;
        _currentPosition = _formatDuration(_videoController.value.position);
      });
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _videoController.pause();
    } else {
      _videoController.play();
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "0:00";
    final minutes = duration.inMinutes.toString().padLeft(1, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
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
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(_videoController),
                          if (!_isPlaying)
                            Center(
                              child: IconButton(
                                icon: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 64.0,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                            ),
                          VideoProgressIndicator(
                            _videoController,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Colors.red,
                              backgroundColor: Colors.black54,
                              bufferedColor: Colors.grey,
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Text(
                              _currentPosition ?? '0:00',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Text(
                              _videoDuration ?? '0:00',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
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

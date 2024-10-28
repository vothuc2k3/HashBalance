import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';

class EditPostWidget extends ConsumerStatefulWidget {
  final Post post;

  const EditPostWidget({
    required this.post,
    super.key,
  });

  @override
  ConsumerState<EditPostWidget> createState() => _EditPostWidgetState();
}

class _EditPostWidgetState extends ConsumerState<EditPostWidget> {
  final TextEditingController _contentController = TextEditingController();

  String? _imageUrl;
  String? _videoUrl;

  File? _imageFile;
  File? _videoFile;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.post.image;
    _videoUrl = widget.post.video;
  }

  void _savePost() {
    ref.read(postControllerProvider.notifier).updatePost(
          widget.post.copyWith(
            content: _contentController.text,
            image: _imageUrl,
            video: _videoUrl,
          ),
        );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _contentController,
          decoration: const InputDecoration(
            labelText: 'Content',
            hintText: 'Enter content',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        _imageUrl != null && _imageUrl!.isNotEmpty
            ? Column(
                children: [
                  Image.network(
                    _imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _imageUrl = null);
                    },
                    child: const Text('Remove Image'),
                  ),
                ],
              )
            : _imageFile != null
                ? Image.file(_imageFile!)
                : ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    child: const Text('Pick Image'),
                  ),
        const SizedBox(height: 16),
        _videoUrl != null && _videoUrl!.isNotEmpty
            ? Column(
                children: [
                  VideoWidget(url: _videoUrl!),
                  TextButton(
                    onPressed: () {
                      setState(() => _videoUrl = null);
                    },
                    child: const Text('Remove Video'),
                  ),
                ],
              )
            : _videoFile != null
                ? VideoWidget(url: _videoFile!.path)
                : ElevatedButton(
                    onPressed: _pickVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    child: const Text('Pick Video'),
                  ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class VideoWidget extends StatefulWidget {
  final String url;

  const VideoWidget({
    required this.url,
    super.key,
  });

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}

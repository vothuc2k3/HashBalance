import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/core/widgets/video_player_widget.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/models/post_model.dart';
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
  List<String> _imageUrls = [];
  final List<File> _newImageFiles = [];
  String? _videoUrl;
  File? _videoFile;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.post.images ?? []);
    _videoUrl = widget.post.video;
    _contentController.text = widget.post.content;

    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    setState(() {
      _hasChanged = true;
    });
  }

  void _savePost() async {
    final result = await ref.read(postControllerProvider.notifier).updatePost(
          widget.post.copyWith(
            content: _contentController.text,
            images: _imageUrls,
          ),
          _newImageFiles.isNotEmpty ? _newImageFiles : null,
          _videoFile,
        );
    result.fold(
      (l) => showToast(false, l.message),
      (r) {
        showToast(true, 'Post updated');
        Navigator.pop(context);
      },
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && await pickedFile.length() >= 20 * 1024 * 1024) {
      showToast(false, 'File size should be less than 20MB');
      return;
    }
    if (pickedFile != null) {
      setState(() {
        _newImageFiles.add(File(pickedFile.path));
        _hasChanged = true;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null && await pickedFile.length() >= 100 * 1024 * 1024) {
      showToast(false, 'File size should be less than 100MB');
      return;
    }
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
        _hasChanged = true;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _imageUrls.length) {
        _imageUrls.removeAt(index);
      } else {
        _newImageFiles.removeAt(index - _imageUrls.length);
      }
      _hasChanged = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        backgroundColor: ref.watch(preferredThemeProvider).second,
        actions: [
          _hasChanged
              ? IconButton(
                  onPressed: _savePost,
                  icon: Icon(
                    Icons.save,
                    color: ref.watch(preferredThemeProvider).approveButtonColor,
                  ),
                )
              : IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.save, color: Colors.grey),
                ),
        ],
      ),
      body: Container(
        color: ref.watch(preferredThemeProvider).first,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
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
              if (_imageUrls.isNotEmpty || _newImageFiles.isNotEmpty)
                Column(
                  children: [
                    StaggeredGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 4.0,
                      crossAxisSpacing: 4.0,
                      children: [
                        ..._imageUrls.map(
                          (image) {
                            final index = _imageUrls.indexOf(image);
                            return _buildImagePreview(image: image, index: index);
                          },
                        ),
                        ..._newImageFiles.map(
                          (file) {
                            final index =
                                _newImageFiles.indexOf(file) + _imageUrls.length;
                            return _buildImagePreview(file: file, index: index);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
                child: const Text(
                  'Pick Image',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _videoUrl != null && _videoUrl!.isNotEmpty
                  ? Column(
                      children: [
                        VideoPlayerWidget(videoUrl: _videoUrl!),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _videoUrl = null;
                              _hasChanged = true;
                            });
                          },
                          child: const Text(
                            'Remove Video',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _videoFile != null
                      ? Column(
                          children: [
                            VideoPlayerWidget(videoUrl: _videoFile!.path),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _videoFile = null;
                                  _hasChanged = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                              child: const Text(
                                'Remove Video',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ElevatedButton(
                          onPressed: _pickVideo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                          ),
                          child: const Text(
                            'Pick Video',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview({String? image, File? file, required int index}) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 1,
            child: image != null
                ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                : Image.file(
                    file!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => _removeImage(index),
        ),
      ],
    );
  }
}

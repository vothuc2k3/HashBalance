import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/comment/screen/comment_container/comment_container.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/conbined_models/comment_data_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:hash_balance/models/user_model.dart';

final currentCommentProvider = Provider<CommentModel>((ref) {
  throw UnimplementedError('currentCommentProvider not overridden');
});

final currentPostProvider = Provider<Post>((ref) {
  throw UnimplementedError('currentPostProvider not overridden');
});

class CommentScreen extends ConsumerStatefulWidget {
  final Post _post;

  const CommentScreen({
    super.key,
    required Post post,
  }) : _post = post;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CommentScreenState();
}

class _CommentScreenState extends ConsumerState<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isEmojiVisible = false;

  void _handleMenuItemClick(String value, String commentId) async {
    switch (value) {
      case 'Option1':
        break;
      case 'Option2':
        // Handle Option 2 action
        break;
      case 'Option3':
        // Handle Option 3 action
        break;
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiVisible = !_isEmojiVisible;
    });
  }

  void _addComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isNotEmpty) {
      final result = await ref
          .watch(commentControllerProvider.notifier)
          .comment(widget._post, commentText);
      result.fold((l) => showToast(false, l.message), (r) {
        _commentController.clear();
        setState(() {
          _isEmojiVisible = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(commentControllerProvider);
    final commentsAsyncValue =
        ref.watch(getPostCommentsProvider(widget._post.id));

    return ProviderScope(
      overrides: [
        currentPostProvider.overrideWithValue(widget._post),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Comments'),
          backgroundColor: Colors.black,
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) =>
                  _handleMenuItemClick(value, 'QPeVjW5xz41AMBxNGneGX'),
              icon: const Icon(Icons.more_horiz),
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'Option1',
                    child: Text('Option 1'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Option2',
                    child: Text('Option 2'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'Option3',
                    child: Text('Option 3'),
                  ),
                ];
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF000000),
                Color(0xFF0D47A1),
                Color(0xFF1976D2),
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: _buildCommentsList(commentsAsyncValue),
              ),
              loading ? const Loading() : _buildInputArea(),
              if (_isEmojiVisible) _buildEmojiPicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsList(
      AsyncValue<List<CommentDataModel>?> commentsAsyncValue) {
    return commentsAsyncValue.when(
      data: (comments) {
        if (comments == null || comments.isEmpty) {
          return Center(
            child: const Text(
              'Be the first one to comment!',
              style: TextStyle(color: Colors.white),
            ).animate(),
          );
        }
        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) =>
              _buildCommentItem(comments[index], comments[index].author),
        );
      },
      error: (error, stackTrace) => ErrorText(
        error: error.toString(),
      ),
      loading: () => const Loading(),
    );
  }

  Widget _buildCommentItem(CommentDataModel comment, UserModel author) {
    return ProviderScope(
      overrides: [
        currentCommentProvider.overrideWithValue(comment.comment),
      ],
      child: CommentItemWidget(author: author),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        color: Colors.black,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.emoji_emotions, color: Colors.white),
              onPressed: _toggleEmojiPicker,
            ),
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _addComment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _commentController.text += emoji.emoji;
        },
        config: Config(
          height: 256,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax: 28 *
                (foundation.defaultTargetPlatform == TargetPlatform.iOS
                    ? 1.20
                    : 1.0),
          ),
          swapCategoryAndBottomBar: false,
          skinToneConfig: const SkinToneConfig(),
          categoryViewConfig: const CategoryViewConfig(),
          bottomActionBarConfig: const BottomActionBarConfig(),
          searchViewConfig: const SearchViewConfig(),
        ),
      ),
    );
  }
}

class CommentItemWidget extends ConsumerWidget {
  const CommentItemWidget({
    super.key,
    required UserModel author,
  }) : _author = author;

  final UserModel _author;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comment = ref.watch(currentCommentProvider);
    final post = ref.watch(currentPostProvider);

    return CommentContainer(
      author: _author,
      comment: comment,
      post: post,
    );
  }
}

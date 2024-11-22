import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/autocomplete_options.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/comment/controller/comment_controller.dart';
import 'package:hash_balance/features/comment/screen/comment_container/comment_container.dart';
import 'package:hash_balance/features/friend/controller/friend_controller.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/models/comment_model.dart';
import 'package:hash_balance/models/conbined_models/comment_data_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:hash_balance/models/user_model.dart';
import 'package:multi_trigger_autocomplete/multi_trigger_autocomplete.dart';

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
  bool _isEmojiVisible = false;
  String? _commentText;
  UserModel? _currentUser;
  final List<UserModel> _selectedUsers = [];
  TextEditingController _internalController = TextEditingController();

  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiVisible = !_isEmojiVisible;
    });
  }

  void _addComment() async {
    if (_commentText != null && _commentText!.isNotEmpty) {
      final result = await ref
          .read(commentControllerProvider.notifier)
          .comment(widget._post, _commentText!, _selectedUsers);

      result.fold((l) => showToast(false, l.message), (r) {
        _selectedUsers.clear();
        _internalController.clear();
        _commentText = null;
        setState(() {
          _isEmojiVisible = false;
        });
      });
    } else {
      showToast(false, 'Please enter content for your comment');
    }
  }

  void _navigateToTaggedUser(String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(targetUid: uid),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentUser = ref.read(userProvider)!;
  }

  @override
  void dispose() {
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Comments'),
          backgroundColor: ref.watch(preferredThemeProvider).second,
        ),
        body: Container(
          decoration: BoxDecoration(
            color: ref.watch(preferredThemeProvider).first,
          ),
          child: Column(
            children: [
              Expanded(
                child: _buildCommentsList(commentsAsyncValue),
              ),
              const Divider(
                height: 1,
                color: Colors.white,
              ),
              if (_selectedUsers.isNotEmpty) _buildTagDisplay(),
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
              'Be the first one to leave a comment!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ).animate().fadeIn(duration: 600.ms).moveY(
                  begin: 30,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),
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
      loading: () => const SizedBox.shrink(),
    );
  }

  Widget _buildCommentItem(CommentDataModel comment, UserModel author) {
    return ProviderScope(
      overrides: [
        currentCommentProvider.overrideWithValue(comment.comment),
      ],
      child: CommentItemWidget(
        author: author,
        navigateToTaggedUser: _navigateToTaggedUser,
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 1.0),
        color: ref.watch(preferredThemeProvider).first,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions, color: Colors.white),
                  onPressed: _toggleEmojiPicker,
                ),
                Expanded(
                  child: MultiTriggerAutocomplete(
                    optionsAlignment: OptionsAlignment.topStart,
                    autocompleteTriggers: [
                      AutocompleteTrigger(
                        trigger: '#',
                        optionsViewBuilder:
                            (context, autocompleteQuery, controller) {
                          return ref
                              .watch(fetchFriendsProvider(_currentUser!.uid))
                              .when(
                                data: (friends) => MentionAutocompleteOptions(
                                  query: autocompleteQuery.query,
                                  friends: friends,
                                  onMentionUserTap: (user) {
                                    final autocomplete =
                                        MultiTriggerAutocomplete.of(context);
                                    autocomplete
                                        .acceptAutocompleteOption(user.name);
                                    if (!_selectedUsers.contains(user)) {
                                      setState(() {
                                        _selectedUsers.add(user);
                                        _commentText = _internalController.text;
                                      });
                                    }
                                  },
                                ),
                                error: (error, stackTrace) => ErrorText(
                                  error: error.toString(),
                                ),
                                loading: () => const SizedBox.shrink(),
                              );
                        },
                      ),
                    ],
                    fieldViewBuilder: (context, controller, focusNode) {
                      _internalController = controller;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          focusNode: focusNode,
                          controller: _internalController,
                          decoration: const InputDecoration(
                            hintText: 'Tag your friends with #...',
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          onChanged: (value) {
                            _commentText = value;
                          },
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _addComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _removeTag(UserModel user) {
    setState(() {
      _selectedUsers.remove(user);
    });
  }

  Widget _buildTagDisplay() {
    return Wrap(
      spacing: 0.1,
      children: _selectedUsers.map((user) {
        return Chip(
          avatar: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.profileImage),
          ),
          label: Text(user.name),
          deleteIcon: const Icon(Icons.close),
          onDeleted: () => _removeTag(user),
        );
      }).toList(),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _commentText = emoji.emoji;
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
    required Function(String) navigateToTaggedUser,
  })  : _author = author,
        _navigateToTaggedUser = navigateToTaggedUser;

  final UserModel _author;
  final Function(String) _navigateToTaggedUser;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comment = ref.watch(currentCommentProvider);
    final post = ref.watch(currentPostProvider);

    return CommentContainer(
      author: _author,
      comment: comment,
      post: post,
      navigateToTaggedUser: _navigateToTaggedUser,
    );
  }
}

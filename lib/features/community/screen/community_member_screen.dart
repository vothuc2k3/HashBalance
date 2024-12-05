import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/theme/controller/preferred_theme.dart';
import 'package:hash_balance/features/user_profile/screen/other_user_profile_screen.dart';
import 'package:hash_balance/features/user_profile/screen/user_profile_screen.dart';
import 'package:hash_balance/models/community_model.dart';
import 'package:hash_balance/models/conbined_models/current_user_role_model.dart';
import 'package:hash_balance/features/community/controller/community_controller.dart';
import 'package:hash_balance/core/widgets/loading.dart';

class CommunityMembersScreen extends ConsumerStatefulWidget {
  final Community community;

  const CommunityMembersScreen({super.key, required this.community});

  @override
  ConsumerState<CommunityMembersScreen> createState() =>
      _CommunityMembersScreenState();
}

class _CommunityMembersScreenState
    extends ConsumerState<CommunityMembersScreen> {
  List<CurrentUserRoleModel?> _members = [];
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMoreMembers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      _loadMoreMembers();
    }
  }

  Future<void> _loadMoreMembers() async {
    setState(() {
      _isLoadingMore = true;
    });

    final newMembers = await ref
        .read(communityControllerProvider.notifier)
        .getMoreCommunityMembers(widget.community.id,
            _members.isNotEmpty ? _members.last!.joinedAt : null);

    if (newMembers.isNotEmpty) {
      setState(() {
        _members.addAll(newMembers);
      });
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _sortMembers() {
    _members.sort((a, b) {
      if (a?.role == 'moderator' && b?.role != 'moderator') {
        return -1;
      } else if (a?.role != 'moderator' && b?.role == 'moderator') {
        return 1;
      }
      return 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.community.name} Members"),
        backgroundColor: ref.watch(preferredThemeProvider).second,
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        color: ref.watch(preferredThemeProvider).first,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(
                initialCommunityMembersProvider(widget.community.id));
          },
          child: ref
              .watch(initialCommunityMembersProvider(widget.community.id))
              .when(
                data: (members) {
                  _members = members;
                  _sortMembers();
                  if (_members.isEmpty) {
                    return const Center(child: Text('No members found'));
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: _members.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _members.length) {
                        return _isLoadingMore
                            ? const Center(child: Loading())
                            : const SizedBox.shrink();
                      }

                      final member = _members[index];
                      return ListTile(
                        onTap: () {
                          if (ref.read(userProvider)!.uid != member.user.uid) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OtherUserProfileScreen(
                                  targetUid: member.user.uid,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UserProfileScreen(),
                              ),
                            );
                          }
                        },
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundImage: CachedNetworkImageProvider(
                              member!.user.profileImage),
                        ),
                        title: Text(
                          member.user.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          member.isCreator
                              ? 'Creator'
                              : member.role[0].toUpperCase() +
                                  member.role.substring(1),
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        trailing: Icon(
                          member.status == 'active'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: member.status == 'active'
                              ? Colors.green
                              : Colors.red,
                          size: 24,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: Loading()),
                error: (error, stackTrace) => Center(
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/common/error_text.dart';
import 'package:hash_balance/core/common/loading_circular.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/authentication/repository/auth_repository.dart';
import 'package:hash_balance/features/community/controller/comunity_controller.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final contentController = TextEditingController();
  String? communityName;
  File? image;
  File? video;

  void createPost(String uid) async {
    final result = await ref.read(postControllerProvider.notifier).createPost(
          uid,
          communityName!,
          image,
          video,
          contentController.text,
        );
    result.fold((l) => showSnackBar(context, l.toString()),
        (r) => showMaterialBanner(context, r.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return Column(
      children: [
        TextField(
          controller: contentController,
        ),
        ref.watch(userCommunitiesProvider).when(
              data: (communities) => Expanded(
                child: ListView.separated(
                  itemCount: communities.length,
                  itemBuilder: (BuildContext context, int index) {
                    final community = communities[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(community.profileImage),
                      ),
                      title: Text(
                        '#=${community.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        communityName = community.name;
                      },
                    );
                  },
                  separatorBuilder: (context, index) {
                    return const Divider();
                  },
                ),
              ),
              error: ((error, stackTrace) {
                return ErrorText(error: error.toString());
              }),
              loading: () {
                return const Loading();
              },
            ),
        IconButton(
          onPressed: () {
            createPost(user!.uid);
          },
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

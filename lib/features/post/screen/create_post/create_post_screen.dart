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
  CreatePostScreenState createState() => CreatePostScreenState();
}

class CreatePostScreenState extends ConsumerState<CreatePostScreen> {
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
    final communityProvider = ref.watch(userCommunitiesProvider);

    return Column(
      children: [
        TextField(
          controller: contentController,
        ),
        communityProvider.when(
          data: (communities) {
            return DropdownButton<String>(
              value: communityName,
              onChanged: (String? newValue) {
                setState(() {
                  communityName = newValue;
                });
              },
              items: communities.map<DropdownMenuItem<String>>((community) {
                return DropdownMenuItem<String>(
                  value: community.name,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(community.profileImage),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#=${community.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          error: (error, stackTrace) {
            return ErrorText(error: error.toString());
          },
          loading: () => const Loading(),
        ),
        IconButton(
          onPressed: () {
            if (communityName != null) {
              createPost(user!.uid);
            } else {
              showSnackBar(context, 'Please select a community');
            }
          },
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

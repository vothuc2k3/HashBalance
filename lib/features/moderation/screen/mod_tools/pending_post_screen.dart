import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/widgets/error_text.dart';
import 'package:hash_balance/core/widgets/loading.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/post_model.dart';

class PendingPostScreen extends ConsumerStatefulWidget {
  final String _communityId;

  const PendingPostScreen({super.key, required String communityId})
      : _communityId = communityId;

  @override
  PendingPostScreenState createState() => PendingPostScreenState();
}

class PendingPostScreenState extends ConsumerState<PendingPostScreen> {
  void showPostDetails(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text('Post Title',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(post.content),
                const SizedBox(height: 20),
                Text('Author: ${post.uid}',
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Approve'),
              onPressed: () {
                Navigator.of(context).pop();
                // approvePost(context, post);
              },
            ),
            TextButton(
              child: const Text('Reject'),
              onPressed: () {
                Navigator.of(context).pop();
                // rejectPost(context, post);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(getPendingPostsProvider(widget._communityId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Posts'),
      ),
      body: posts.when(
        data: (posts) {
          if (posts == null) {
            return const Text('There\'s no pending posts...');
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.all(10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 5,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15.0),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(post.content),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Author: Authorrrr',
                              style: TextStyle(fontStyle: FontStyle.italic)),
                          Text(
                              'Status: ${post.status == 'Approved' ? 'Approved' : 'Pending'}'),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String result) {
                      // if (result == 'approve') {
                      //   approvePost(context, post);
                      // } else if (result == 'reject') {
                      //   rejectPost(context, post);
                      // }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'approve',
                        child: ListTile(
                          leading: Icon(Icons.check, color: Colors.green),
                          title: Text('Approve'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'reject',
                        child: ListTile(
                          leading: Icon(Icons.clear, color: Colors.red),
                          title: Text('Reject'),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    showPostDetails(context, post);
                  },
                ),
              );
            },
          );
        },
        error: (error, stackTrace) => ErrorText(error: error.toString()),
        loading: () => const Loading(),
      ),
    );
  }
}

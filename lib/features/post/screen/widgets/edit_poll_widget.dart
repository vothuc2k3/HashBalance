import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hash_balance/core/utils.dart';
import 'package:hash_balance/features/post/controller/post_controller.dart';
import 'package:hash_balance/models/poll_option_model.dart';
import 'package:hash_balance/models/post_model.dart';
import 'package:uuid/uuid.dart';

class EditPollWidget extends ConsumerStatefulWidget {
  final Post post;
  final List<PollOption> pollOptions;

  const EditPollWidget({
    required this.post,
    required this.pollOptions,
    super.key,
  });

  @override
  ConsumerState<EditPollWidget> createState() => _EditPollWidgetState();
}

class _EditPollWidgetState extends ConsumerState<EditPollWidget> {
  late TextEditingController _contentController;
  late List<TextEditingController> pollOptionControllers;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
    pollOptionControllers = widget.pollOptions
        .map((option) => TextEditingController(text: option.option))
        .toList();
  }

  @override
  void dispose() {
    _contentController.dispose();
    for (var controller in pollOptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _savePoll() async {
    final result = await ref.read(postControllerProvider.notifier).updatePoll(
          widget.post.copyWith(content: _contentController.text),
          widget.pollOptions,
        );
    result.fold((l) => showToast(false, l.message),
        (r) => showToast(true, 'Poll updated'));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Poll Question',
                  hintText: 'Enter poll question',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.pollOptions.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      TextField(
                        controller: pollOptionControllers[index],
                        onChanged: (value) {
                          setState(() {
                            widget.pollOptions[index] = widget
                                .pollOptions[index]
                                .copyWith(option: value);
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1}',
                          border: const OutlineInputBorder(),
                          suffixIcon: widget.pollOptions.length > 2
                              ? IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      widget.pollOptions.removeAt(index);
                                      pollOptionControllers.removeAt(index);
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    final newOption = PollOption(
                      option: '',
                      id: const Uuid().v4(),
                      pollId: widget.post.id,
                    );
                    widget.pollOptions.add(newOption);
                    pollOptionControllers
                        .add(TextEditingController(text: newOption.option));
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
                child: const Text(
                  'Add Option',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: IconButton(
            icon: const Icon(Icons.save, color: Colors.green),
            onPressed: _savePoll,
          ),
        ),
      ],
    );
  }
}

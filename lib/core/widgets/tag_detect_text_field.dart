import 'package:flutter/material.dart';

class TagDetectTextField extends StatefulWidget {
  final List<String> validTags;

  const TagDetectTextField({super.key, required this.validTags});

  @override
  State<TagDetectTextField> createState() => _TagDetectTextFieldState();
}

class _TagDetectTextFieldState extends State<TagDetectTextField> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          Positioned.fill(
            child: RichText(
              text: _buildRichText(_controller.text),
            ),
          ),
          TextField(
            controller: _controller,
            style: const TextStyle(color: Colors.transparent),
            cursorColor: Colors.black,
            decoration: const InputDecoration(
              hintText: 'Tag a friend with #...',
              border: OutlineInputBorder(),
            ),
            onChanged: (text) {
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  TextSpan _buildRichText(String text) {
    List<String> words = text.split(' ');
    List<TextSpan> spans = [];

    for (String word in words) {
      if (word.startsWith('#') &&
          widget.validTags.contains(word.substring(1))) {
        spans.add(TextSpan(
          text: '$word ',
          style:
              const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ));
      } else {
        // Các từ thông thường
        spans.add(TextSpan(
          text: '$word ',
          style: const TextStyle(color: Colors.black),
        ));
      }
    }

    return TextSpan(children: spans);
  }
}

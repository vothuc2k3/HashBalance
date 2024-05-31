import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  var cardHeightWidth = 120.0;
  var iconSize = 60.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {},
          child: SizedBox(
            height: cardHeightWidth,
            width: cardHeightWidth,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 16,
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: SizedBox(
            height: cardHeightWidth,
            width: cardHeightWidth,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 16,
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: SizedBox(
            height: cardHeightWidth,
            width: cardHeightWidth,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 16,
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

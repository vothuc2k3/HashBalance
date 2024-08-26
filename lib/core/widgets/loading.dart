import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Loading extends StatelessWidget {
  final bool? isVote;

  const Loading({super.key, this.isVote});

  const Loading.vote({super.key}) : isVote = true;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isVote == true
          ? LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.orange,
              size: 20,
            )
          : LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.white,
              size: 40,
            ),
    );
  }
}

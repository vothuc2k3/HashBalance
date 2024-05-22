import 'package:flutter/material.dart';
import 'package:hash_balance/core/common/loading_circular.dart';

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoadingCircular();
  }
}

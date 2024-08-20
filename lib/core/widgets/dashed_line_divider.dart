import 'package:flutter/material.dart';

class DashedLineDivider extends StatelessWidget {
  final double height;
  final double width;
  final double dashLength;
  final double dashSpace;
  final Color color;
  final bool isVertical;

  const DashedLineDivider.horizontal({
    super.key,
    this.height = 2.0,
    this.dashLength = 5.0,
    this.dashSpace = 3.0,
    this.color = Colors.white,
  })  : width = double.infinity,
        isVertical = false;

  const DashedLineDivider.vertical({
    super.key,
    this.width = 2.0,
    this.dashLength = 5.0,
    this.dashSpace = 3.0,
    this.color = Colors.white,
  })  : height = double.infinity,
        isVertical = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalLength = isVertical
            ? constraints.constrainHeight()
            : constraints.constrainWidth();
        final int dashCount = (totalLength / (dashLength + dashSpace)).floor();

        return Flex(
          direction: isVertical ? Axis.vertical : Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: isVertical ? width : dashLength,
              height: isVertical ? dashLength : height,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}

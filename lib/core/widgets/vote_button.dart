import 'package:flutter/material.dart';

class VoteButton extends StatefulWidget {
  final IconData icon;
  final int? count;
  final Color? color;
  final Function onTap;
  final bool isUpvote;

  const VoteButton({
    super.key,
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
    required this.isUpvote,
  });

  @override
  VoteButtonState createState() => VoteButtonState();
}

class VoteButtonState extends State<VoteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(_controller);
  }

  void _handleTap() {
    if (mounted) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
    }

    widget.onTap(widget.isUpvote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: InkWell(
        onTap: _handleTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              Icon(widget.icon, color: widget.color, size: 20),
              const SizedBox(width: 4),
              Text(
                widget.count == null ? '0' : widget.count.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
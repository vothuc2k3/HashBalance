import 'package:flutter/material.dart';

class PostStaticButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Function onTap;

  const PostStaticButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(15), // Giảm kích thước borderRadius
      child: Container(
        decoration: BoxDecoration(
          color: Colors.purple[800],
          borderRadius: BorderRadius.circular(15), // Giảm kích thước borderRadius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              spreadRadius: 1.5,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          gradient: const LinearGradient(
            colors: [
              Color(0xFF5E35B1),
              Color(0xFF7E57C2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Giảm padding
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18, // Giảm kích thước icon
            ),
            const SizedBox(width: 4), // Giảm khoảng cách giữa icon và label
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14, // Giảm kích thước font
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

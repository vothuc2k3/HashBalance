import 'package:flutter/material.dart';

Color dark = const Color.fromARGB(255, 29, 37, 46);
const Color grey = Color.fromARGB(255, 56, 59, 62);
Color navy = const Color(0xff302d3e);

double width(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

double height(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

Widget backIcon(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back),
      ),
    ],
  );
}

ButtonStyle buttonStyle(Color foreColor, {Color backColor = Colors.white}) {
  return ButtonStyle(
    foregroundColor: WidgetStateProperty.all<Color>(foreColor),
    backgroundColor: WidgetStateProperty.all<Color>(backColor),
  );
}

class Project {
  final String img;
  final String title;
  final Color color;
  final Widget details;

  Project.fromMap(data)
      : img = data['img'],
        title = data['title'],
        color = data['color'],
        details = data['details'];
}

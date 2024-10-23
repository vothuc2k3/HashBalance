import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final preferredThemeProvider =
    StateNotifierProvider<PreferredTheme, ThemeColors>(
  (ref) => PreferredTheme(),
);

class PreferredTheme extends StateNotifier<ThemeColors> {
  PreferredTheme() : super(_firstTheme);

  static const ThemeColors _firstTheme = ThemeColors(
    first: Color(0xFF1F4D35),
    second: Color(0xFF193D2B),
    third: Color(0xFF132E21),

    // first: Color(0xFF232845),
    // second: Color(0xFF1B1E36), // Darker shade
    // third: Color(0xFF101224), // Even darker shade
    approveButtonColor: Color(0xFF4CAF50), // Green color for approve
    declineButtonColor: Color(0xFFF44336), // Red color for decline
    transparentButtonColor: Color(0x00000000), // Transparent color
  );

  static const ThemeColors _secondTheme = ThemeColors(
    first: Color(0xFFE63946),
    second: Color(0xFFB6313A), // Darker shade
    third: Color(0xFF7D2328), // Even darker shade
    approveButtonColor: Color(0xFF4CAF50), // Green color for approve
    declineButtonColor: Color(0xFFF44336), // Red color for decline
    transparentButtonColor: Color(0x00000000), // Transparent color
  );

  void changeTheme() {
    state = (state == _firstTheme) ? _secondTheme : _firstTheme;
  }

  void setTheme(ThemeColors theme) {
    state = theme;
  }

  void resetTheme() {
    state = _firstTheme;
  }
}

class ThemeColors {
  final Color first;
  final Color second;
  final Color third;
  final Color approveButtonColor; // Color for approve button
  final Color declineButtonColor; // Color for decline button
  final Color transparentButtonColor; // Color for transparent button

  const ThemeColors({
    required this.first,
    required this.second,
    required this.third,
    required this.approveButtonColor,
    required this.declineButtonColor,
    required this.transparentButtonColor,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final preferredThemeProvider =
    StateNotifierProvider<PreferredTheme, ThemeColors>(
  (ref) => PreferredTheme(),
);

class PreferredTheme extends StateNotifier<ThemeColors> {
  PreferredTheme() : super(_firstTheme);

  static const ThemeColors _firstTheme = ThemeColors(
    first: Color(0xFF232845),
    second: Color(0xFF1B1E36), // Darker shade
    third: Color(0xFF101224), // Even darker shade
  );

  static const ThemeColors _secondTheme = ThemeColors(
    first: Color(0xFFE63946),
    second: Color(0xFFB6313A), // Darker shade
    third: Color(0xFF7D2328), // Even darker shade
  );

  void changeTheme() {
    state = _secondTheme;
  }

  void resetTheme() {
    state = _firstTheme;
  }
}

class ThemeColors {
  final Color first;
  final Color second;
  final Color third;

  const ThemeColors({
    required this.first,
    required this.second,
    required this.third,
  });
}

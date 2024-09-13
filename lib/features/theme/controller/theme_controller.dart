import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PreferredTheme extends StateNotifier<Color> {
  PreferredTheme() : super(_firstTheme);

  static const Color _firstTheme = Color(0xFF232845);
  static const Color _secondTheme = Color(0xFFE63946);

  void changeTheme() {
    state = _secondTheme;
  }

  // Method to reset to the default theme.
  void resetTheme() {
    state = _firstTheme;
  }
}

final preferredThemeProvider = StateNotifierProvider<PreferredTheme, Color>(
  (ref) => PreferredTheme(),
);

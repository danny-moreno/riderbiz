import 'package:flutter/material.dart';

// Initial UI reference values; exact brand tokens pending verification.
const ink = Color(0xFF002D33);
const teal = Color(0xFF00AEA6);
const lime = Color(0xFFBEF524);
const surface = Color(0xFFF4F9FA);

ThemeData riderBizTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: surface,
  colorScheme: ColorScheme.fromSeed(
    seedColor: teal,
    primary: teal,
    secondary: lime,
    surface: surface,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: lime,
      foregroundColor: ink,
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
);

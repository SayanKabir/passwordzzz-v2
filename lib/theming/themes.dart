import 'package:flutter/material.dart';

const Color primaryColor = Color(0xff0ba99b);
const Color lightThemePrimaryColor = Color(0xffddfffa);

class MyThemes {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.black,
    primaryColor: Colors.black,
    // shadowColor: Colors.white,
    colorScheme: const ColorScheme.dark().copyWith(
      primary: const Color(0xffccffff),
    ),
    iconTheme: const IconThemeData(color: Colors.white, opacity: 0.8),
    cardColor: const Color(0xff1f1f1f),
    // cardColor: Colors.black,
  );

  static final lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xffffffff),
    primaryColor: Colors.white,
    colorScheme: const ColorScheme.light().copyWith(
      onBackground: Colors.black,
      primary: const Color(0xff1d5c5c),
    ),
    iconTheme: const IconThemeData(color: Colors.black, opacity: 0.8),
    cardColor: const Color(0xfff1f5f5),
  );
}
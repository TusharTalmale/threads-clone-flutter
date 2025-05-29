import 'package:flutter/material.dart';

final ThemeData theme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    elevation: 0.0,
    surfaceTintColor: Colors.black,
  ),
  colorScheme: const ColorScheme.dark(
    background: Colors.black,
    onBackground: Colors.white,
    surfaceTint: Colors.black12,
    primary: Colors.black,
    onPrimary: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      foregroundColor: MaterialStatePropertyAll(Colors.black),
      backgroundColor: MaterialStatePropertyAll(Colors.white),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
    indicatorColor: Colors.transparent,
    height: 55,
    backgroundColor: Colors.black,
    iconTheme: MaterialStatePropertyAll(
      IconThemeData(
        color: Colors.white,
        size: 30,
      ),
    ),
  ),
);

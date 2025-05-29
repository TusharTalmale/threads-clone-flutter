import 'package:flutter/material.dart';

ButtonStyle customOutlinestyle() {
  return ButtonStyle(
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
    ),
    textStyle: MaterialStateProperty.all(
      const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    foregroundColor: MaterialStateProperty.all(Colors.white),
    side: MaterialStateProperty.all(
      const BorderSide(color: Colors.white12),
    ),
  );
}

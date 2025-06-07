import 'package:flutter/material.dart';
import 'package:thread_app/utils/type_def.dart';

class SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final InputCallback callback;

  const SearchInput({super.key, required this.controller, required this.callback});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: callback, // Will trigger the debounced search in Search widget
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Color(0xff242424),
        hintText: "Search Users or Posts",
        hintStyle: TextStyle(color: Colors.grey),
        contentPadding: EdgeInsetsDirectional.symmetric(
          vertical: 10,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15.0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15.0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15.0)),
        ),
      ),
    );
  }
}
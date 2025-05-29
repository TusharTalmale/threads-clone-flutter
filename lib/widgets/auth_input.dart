import 'package:flutter/material.dart';
import 'package:thread_app/utils/type_def.dart';

class AuthInput extends StatelessWidget {
  final String label, hintText;
  final bool isPass;
  final TextEditingController controller;
  final ValidatorCallback validatorCallback;
  const AuthInput({
    super.key,
    required this.validatorCallback,
    required this.label,
    required this.hintText,
    this.isPass = false,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validatorCallback,
      obscureText: isPass,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        label: Text(label),
        hintText: hintText,
      ),
    );
  }
}

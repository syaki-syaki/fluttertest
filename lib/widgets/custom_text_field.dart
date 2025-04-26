// lib/widgets/custom_text_field.dart

import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isMultiline;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      maxLines: isMultiline ? null : 1,
    );
  }
}

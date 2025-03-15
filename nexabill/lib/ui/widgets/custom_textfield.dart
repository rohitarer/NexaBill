import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String? label; // Optional Label
  final String? hintText; // Optional Hint
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final IconData? prefixIcon; // Leading Icon (Optional)
  final IconData? suffixIcon; // Trailing Icon (Optional)
  final VoidCallback? onSuffixIconTap; // Action for Trailing Icon (Optional)
  final String? Function(String?)? validator; // Validation Function (Optional)
  final bool autoFocus;
  final bool readOnly;
  final int maxLines;
  final int minLines;

  // NEW Parameters
  final Color? textColor; // Input Text Color
  final Color? hintColor; // Hint Text Color
  final Color? labelColor; // Label Text Color
  final Color? prefixIconColor; // Prefix Icon Color
  final Color? suffixIconColor; // Suffix Icon Color
  final Color? fillColor; // Background Color for Input Field (NEW)

  const CustomTextField({
    super.key,
    this.label,
    this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.validator,
    this.autoFocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines = 1,
    this.textColor, // NEW
    this.hintColor, // NEW
    this.labelColor, // NEW
    this.prefixIconColor, // NEW
    this.suffixIconColor, // NEW
    this.fillColor, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: labelColor ?? Colors.black, // Dynamic Label Color
              ),
            ),
          ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          validator: validator,
          autofocus: autoFocus,
          readOnly: readOnly,
          maxLines: maxLines,
          minLines: minLines,
          style: TextStyle(
            color: textColor ?? Colors.black, // Dynamic Input Text Color
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor ?? Colors.white, // Dynamic Background Color
            hintText: hintText,
            hintStyle: TextStyle(
              color: hintColor ?? Colors.grey, // Dynamic Hint Text Color
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            prefixIcon:
                prefixIcon != null
                    ? Icon(prefixIcon, color: prefixIconColor ?? Colors.black54)
                    : null,
            suffixIcon:
                suffixIcon != null
                    ? GestureDetector(
                      onTap: onSuffixIconTap,
                      child: Icon(
                        suffixIcon,
                        color: suffixIconColor ?? Colors.black54,
                      ),
                    )
                    : null,
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

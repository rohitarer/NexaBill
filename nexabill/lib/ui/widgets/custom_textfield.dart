import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final String? Function(String?)? validator;
  final bool autoFocus;
  final bool readOnly;
  final bool enabled;
  final int maxLines;
  final int minLines;
  final Color? textColor;
  final Color? hintColor;
  final Color? labelColor;
  final Color? prefixIconColor;
  final Color? suffixIconColor;
  final Color? fillColor;
  final Function(String)? onChanged;
  final VoidCallback? onTap; // ✅ Added onTap for Date Picker Support

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
    this.enabled = true,
    this.maxLines = 1,
    this.minLines = 1,
    this.textColor,
    this.hintColor,
    this.labelColor,
    this.prefixIconColor,
    this.suffixIconColor,
    this.fillColor,
    this.onChanged,
    this.onTap, // ✅ Added this to handle Date Picker taps
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
                color: labelColor ?? Colors.black,
              ),
            ),
          ),
        SizedBox(
          width: double.infinity, // ✅ Ensures it takes full width
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword,
            validator: validator,
            autofocus: autoFocus,
            readOnly: readOnly,
            enabled: enabled,
            maxLines: maxLines,
            minLines: minLines,
            style: TextStyle(color: textColor ?? Colors.black),
            onChanged: onChanged,
            onTap: onTap, // ✅ Now supports Date Picker taps
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor ?? Colors.white,
              hintText: hintText,
              hintStyle: TextStyle(color: hintColor ?? Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: prefixIconColor ?? Colors.black54)
                  : null,
              suffixIcon: suffixIcon != null
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
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

// class CustomTextField extends StatelessWidget {
//   final String? label; // Optional Label
//   final String? hintText; // Optional Hint
//   final TextEditingController controller;
//   final TextInputType keyboardType;
//   final bool isPassword;
//   final IconData? prefixIcon; // Leading Icon (Optional)
//   final IconData? suffixIcon; // Trailing Icon (Optional)
//   final VoidCallback? onSuffixIconTap; // Action for Trailing Icon (Optional)
//   final String? Function(String?)? validator; // Validation Function (Optional)
//   final bool autoFocus;
//   final bool readOnly;
//   final bool enabled; // ✅ New: Enables/Disables Input Field
//   final int maxLines;
//   final int minLines;

//   // NEW Parameters
//   final Color? textColor; // Input Text Color
//   final Color? hintColor; // Hint Text Color
//   final Color? labelColor; // Label Text Color
//   final Color? prefixIconColor; // Prefix Icon Color
//   final Color? suffixIconColor; // Suffix Icon Color
//   final Color? fillColor; // Background Color for Input Field

//   const CustomTextField({
//     super.key,
//     this.label,
//     this.hintText,
//     required this.controller,
//     this.keyboardType = TextInputType.text,
//     this.isPassword = false,
//     this.prefixIcon,
//     this.suffixIcon,
//     this.onSuffixIconTap,
//     this.validator,
//     this.autoFocus = false,
//     this.readOnly = false,
//     this.enabled = true, // ✅ Default: Input field is enabled
//     this.maxLines = 1,
//     this.minLines = 1,
//     this.textColor,
//     this.hintColor,
//     this.labelColor,
//     this.prefixIconColor,
//     this.suffixIconColor,
//     this.fillColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (label != null)
//           Padding(
//             padding: const EdgeInsets.only(bottom: 5),
//             child: Text(
//               label!,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: labelColor ?? Colors.black,
//               ),
//             ),
//           ),
//         TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           obscureText: isPassword,
//           validator: validator,
//           autofocus: autoFocus,
//           readOnly: readOnly,
//           enabled: enabled, // ✅ Controls input field state
//           maxLines: maxLines,
//           minLines: minLines,
//           style: TextStyle(color: textColor ?? Colors.black),
//           decoration: InputDecoration(
//             filled: true,
//             fillColor: fillColor ?? Colors.white,
//             hintText: hintText,
//             hintStyle: TextStyle(color: hintColor ?? Colors.grey),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: const BorderSide(color: Colors.black12),
//             ),
//             prefixIcon:
//                 prefixIcon != null
//                     ? Icon(prefixIcon, color: prefixIconColor ?? Colors.black54)
//                     : null,
//             suffixIcon:
//                 suffixIcon != null
//                     ? GestureDetector(
//                       onTap: onSuffixIconTap,
//                       child: Icon(
//                         suffixIcon,
//                         color: suffixIconColor ?? Colors.black54,
//                       ),
//                     )
//                     : null,
//           ),
//         ),
//         const SizedBox(height: 15),
//       ],
//     );
//   }
// }

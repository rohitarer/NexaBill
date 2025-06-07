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
  final int? maxLength;
  final Color? textColor;
  final Color? hintColor;
  final Color? labelColor;
  final Color? prefixIconColor;
  final Color? suffixIconColor;
  final Color? fillColor;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final TextAlign textAlign;
  final TextStyle? textStyle;

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
    this.maxLength,
    this.textColor,
    this.hintColor,
    this.labelColor,
    this.prefixIconColor,
    this.suffixIconColor,
    this.fillColor,
    this.onChanged,
    this.onTap,
    this.textAlign = TextAlign.start,
    this.textStyle,
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
          width: double.infinity,
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
            maxLength: maxLength,
            onChanged: onChanged,
            onTap: onTap,
            textAlign: textAlign,
            style: textStyle ?? TextStyle(color: textColor ?? Colors.black),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: fillColor ?? Colors.white,
              hintText: hintText,
              hintStyle: TextStyle(color: hintColor ?? Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black12),
              ),
              prefixIcon:
                  prefixIcon != null
                      ? Icon(
                        prefixIcon,
                        color: prefixIconColor ?? Colors.black54,
                      )
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
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

// import 'package:flutter/material.dart';

// class CustomTextField extends StatelessWidget {
//   final String? label;
//   final String? hintText;
//   final TextEditingController controller;
//   final TextInputType keyboardType;
//   final bool isPassword;
//   final IconData? prefixIcon;
//   final IconData? suffixIcon;
//   final VoidCallback? onSuffixIconTap;
//   final String? Function(String?)? validator;
//   final bool autoFocus;
//   final bool readOnly;
//   final bool enabled;
//   final int maxLines;
//   final int minLines;
//   final int? maxLength;
//   final Color? textColor;
//   final Color? hintColor;
//   final Color? labelColor;
//   final Color? prefixIconColor;
//   final Color? suffixIconColor;
//   final Color? fillColor;
//   final Function(String)? onChanged;
//   final VoidCallback? onTap;

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
//     this.enabled = true,
//     this.maxLines = 1,
//     this.minLines = 1,
//     this.maxLength,
//     this.textColor,
//     this.hintColor,
//     this.labelColor,
//     this.prefixIconColor,
//     this.suffixIconColor,
//     this.fillColor,
//     this.onChanged,
//     this.onTap,
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
//         SizedBox(
//           width: double.infinity,
//           child: TextFormField(
//             controller: controller,
//             keyboardType: keyboardType,
//             obscureText: isPassword,
//             validator: validator,
//             autofocus: autoFocus,
//             readOnly: readOnly,
//             enabled: enabled,
//             maxLines: maxLines,
//             minLines: minLines,
//             maxLength: maxLength,
//             style: TextStyle(color: textColor ?? Colors.black),
//             onChanged: onChanged,
//             onTap: onTap,
//             decoration: InputDecoration(
//               counterText: '', // ✅ Hides character counter for cleaner UI
//               filled: true,
//               fillColor: fillColor ?? Colors.white,
//               hintText: hintText,
//               hintStyle: TextStyle(color: hintColor ?? Colors.grey),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: const BorderSide(color: Colors.black12),
//               ),
//               prefixIcon:
//                   prefixIcon != null
//                       ? Icon(
//                         prefixIcon,
//                         color: prefixIconColor ?? Colors.black54,
//                       )
//                       : null,
//               suffixIcon:
//                   suffixIcon != null
//                       ? GestureDetector(
//                         onTap: onSuffixIconTap,
//                         child: Icon(
//                           suffixIcon,
//                           color: suffixIconColor ?? Colors.black54,
//                         ),
//                       )
//                       : null,
//             ),
//           ),
//         ),
//         const SizedBox(height: 15),
//       ],
//     );
//   }
// }

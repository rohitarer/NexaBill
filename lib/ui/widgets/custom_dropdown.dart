import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String? value;
  final String hintText;
  final List<String> items;
  final void Function(String?) onChanged;

  final Color? textColor;
  final Color? hintColor;
  final Color? fillColor;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Color? iconColor;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.textColor,
    this.hintColor,
    this.fillColor,
    this.prefixIcon,
    this.suffixIcon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor ?? Colors.white, // ✅ Background color
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIcon:
            prefixIcon != null
                ? Icon(prefixIcon, color: iconColor ?? Colors.grey)
                : null, // ✅ Optional Prefix Icon
        suffixIcon:
            suffixIcon != null
                ? Icon(suffixIcon, color: iconColor ?? Colors.grey)
                : null, // ✅ Optional Suffix Icon
      ),
      hint: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          hintText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: hintColor ?? Colors.grey, // ✅ Hint text color
          ),
        ),
      ),
      style: TextStyle(color: textColor ?? Colors.black, fontSize: 16),
      dropdownColor: fillColor ?? Colors.white,
      items:
          items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(color: textColor ?? Colors.black),
              ),
            );
          }).toList(),
    );
  }
}

// import 'package:flutter/material.dart';

// class CustomDropdown extends StatelessWidget {
//   final String? value;
//   final String hintText;
//   final List<String> items;
//   final void Function(String?) onChanged;

//   final Color? textColor;
//   final Color? hintColor;
//   final Color? fillColor;

//   const CustomDropdown({
//     super.key,
//     required this.value,
//     required this.hintText,
//     required this.items,
//     required this.onChanged,
//     this.textColor,
//     this.hintColor,
//     this.fillColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return DropdownButtonFormField<String>(
//       value: value,
//       onChanged: onChanged,
//       decoration: InputDecoration(
//         filled: true,
//         fillColor: fillColor ?? Colors.white,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 14,
//         ),
//       ),
//       hint: Text(hintText, style: TextStyle(color: hintColor ?? Colors.grey)),
//       style: TextStyle(color: textColor ?? Colors.black, fontSize: 16),
//       dropdownColor: fillColor ?? Colors.white,
//       items:
//           items.map((String item) {
//             return DropdownMenuItem<String>(
//               value: item,
//               child: Text(
//                 item,
//                 style: TextStyle(color: textColor ?? Colors.black),
//               ),
//             );
//           }).toList(),
//     );
//   }
// }

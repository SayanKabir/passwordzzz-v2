import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:passwordzzz_v2/theming/themes.dart';

class MyButton extends StatelessWidget {
  final Color backgroundColor;
  final double borderRadius;
  final double width;
  final Widget child;
  final VoidCallback onPressed;
  const MyButton({super.key, required this.width, required this.child, required this.onPressed, this.borderRadius = 14, this.backgroundColor = primaryColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: backgroundColor,
        ),
        child: Center(
          child: child,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

SnackBar mySnackbar(BuildContext context, String message) => SnackBar(
  elevation: 0,
  padding: const EdgeInsets.all(20),
  width: MediaQuery.of(context).size.width * 0.021 * message.length,
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(30),
  ),
  duration: const Duration(milliseconds: 2000),
  backgroundColor: Colors.white.withOpacity(0.9),
  content: Text(
    message,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: Colors.black87,
    ),
  ),
);
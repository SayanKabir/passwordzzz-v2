import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HapticType {Selection, Action}

Future<void> hapticFeedback(BuildContext context, HapticType type) async{
  bool? isHapticsEnabled;
  final prefs = await SharedPreferences.getInstance();
  isHapticsEnabled = prefs.getBool("isHapticsEnabled") ?? true;

  if(isHapticsEnabled){
    if(type==HapticType.Selection) {
      await HapticFeedback.selectionClick();
    } else {
      await HapticFeedback.lightImpact();
    }
  }
}
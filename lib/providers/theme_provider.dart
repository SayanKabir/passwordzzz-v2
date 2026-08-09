import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../utils/shared_prefs_handler.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  ThemeMode getThemeMode() => themeMode;

  ThemeProvider(){
    SharedPrefsHandler.readData(tag: "isDarkMode").then((value){
      if(value==true) {
        themeMode=ThemeMode.dark;
      } else if(value==false) {
        themeMode = ThemeMode.light;
      }
      else {
        themeMode = ThemeMode.system;
      }

      notifyListeners();
    });
  }
  bool get isDarkMode {
    if (themeMode == ThemeMode.system) {
      final brightness = SchedulerBinding.instance.window.platformBrightness;
      return brightness == Brightness.dark;
    } else {
      return themeMode == ThemeMode.dark;
    }
  }
  void toggleTheme() async{
    if (isDarkMode) {
      themeMode = ThemeMode.light;
    } else {
      themeMode = ThemeMode.dark;
    }

    SharedPrefsHandler.saveData(tag: "isDarkMode", data: isDarkMode);
    notifyListeners();
  }
}

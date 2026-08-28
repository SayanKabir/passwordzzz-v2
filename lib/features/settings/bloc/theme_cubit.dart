import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's theme choice.
///
/// v1 read the deprecated `SchedulerBinding.instance.window.platformBrightness`
/// to seed this; [ThemeMode.system] lets the framework handle it and reacts to
/// live OS changes for free.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'themeMode';

  static ThemeMode _read(SharedPreferences prefs) {
    return switch (prefs.getString(_key)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    emit(mode);
    await _prefs.setString(_key, mode.name);
  }

  /// Cycles system -> light -> dark -> system, for the app-bar toggle.
  Future<void> cycle() => set(switch (state) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  });
}

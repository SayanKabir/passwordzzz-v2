import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_lock_state.dart';

/// Owns the lock lifecycle: unlock, manual lock, and the background auto-lock
/// timer.
///
/// Phase 0 has no crypto behind it — [unlock] simply transitions. Phase 1
/// replaces the body of [unlock] with the biometric prompt and Keystore
/// unwrap; the states, the timer, and the router guard stay exactly as they
/// are, so nothing downstream changes.
class AppLockCubit extends Cubit<AppLockState> with WidgetsBindingObserver {
  AppLockCubit() : super(const LockLocked()) {
    WidgetsBinding.instance.addObserver(this);
  }

  Timer? _autoLockTimer;

  /// How long the app may sit in the background before it re-locks.
  static const autoLockAfter = Duration(seconds: 60);

  Future<void> unlock() async {
    if (state is LockUnlocking) return;
    emit(const LockUnlocking());

    // Phase 1: biometric prompt -> Keystore unwrap -> vault key.
    await Future<void>.delayed(const Duration(milliseconds: 150));

    emit(const LockUnlocked());
  }

  /// Drops the vault key and returns to [LockLocked].
  void lock({String? reason}) {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;
    // Phase 1: zero the key bytes before dropping the reference.
    emit(LockLocked(reason: reason));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (this.state is LockUnlocked) {
          _autoLockTimer?.cancel();
          _autoLockTimer = Timer(autoLockAfter, () => lock());
        }
      case AppLifecycleState.resumed:
        _autoLockTimer?.cancel();
        _autoLockTimer = null;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Future<void> close() {
    _autoLockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }
}

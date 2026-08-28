import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/crypto/biometric_authenticator.dart';
import 'app_lock_state.dart';

/// Owns the lock lifecycle: unlock, manual lock, and the background auto-lock
/// timer.
///
/// Phase 0 has no crypto behind it — [unlock] simply transitions. Phase 1
/// replaces the body of [unlock] with the biometric prompt and Keystore
/// unwrap; the states, the timer, and the router guard stay exactly as they
/// are, so nothing downstream changes.
class AppLockCubit extends Cubit<AppLockState> with WidgetsBindingObserver {
  AppLockCubit({BiometricAuthenticator? authenticator})
    : _auth = authenticator ?? LocalAuthAuthenticator(),
      super(const LockLocked()) {
    WidgetsBinding.instance.addObserver(this);
  }

  final BiometricAuthenticator _auth;

  Timer? _autoLockTimer;

  /// How long the app may sit in the background before it re-locks.
  static const autoLockAfter = Duration(seconds: 60);

  Future<void> unlock() async {
    if (state is LockUnlocking) return;
    emit(const LockUnlocking());

    final outcome = await _auth.authenticate(
      reason: 'Unlock your Passwordzzz vault',
    );

    // Phase 1 inserts the Keystore unwrap here: a successful prompt releases
    // the wrapped vault key, which then rides in LockUnlocked.
    switch (outcome) {
      case AuthSucceeded():
        emit(const LockUnlocked());
      case AuthCancelled():
        // Dismissing the prompt is not an error; say nothing.
        emit(const LockLocked());
      case AuthNotSetUp():
        emit(
          const LockLocked(
            reason:
                'Passwordzzz needs a screen lock. Add a PIN, pattern, or '
                'fingerprint in your device settings, then try again.',
          ),
        );
      case AuthLockedOut(permanent: final permanent):
        emit(
          LockLocked(
            reason: permanent
                ? 'Too many attempts. Unlock your device with its PIN or '
                      'password, then reopen Passwordzzz.'
                : 'Too many attempts. Wait a moment and try again.',
          ),
        );
      case AuthFailed(message: final message):
        emit(LockLocked(reason: message));
    }
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

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/crypto/keystore_channel.dart';
import 'app_lock_state.dart';

/// Owns the lock lifecycle: first-run key creation, unlock, manual lock, and
/// the background auto-lock timer.
///
/// The prompt and the unwrap are a single native call. They cannot be split:
/// the Keystore cipher is bound to the prompt through a CryptoObject, which is
/// what makes the authentication cryptographic rather than cosmetic.
class AppLockCubit extends Cubit<AppLockState> with WidgetsBindingObserver {
  AppLockCubit({KeystoreChannel? keystore})
    : _keystore = keystore ?? MethodChannelKeystore(),
      super(const LockChecking()) {
    WidgetsBinding.instance.addObserver(this);
  }

  final KeystoreChannel _keystore;
  Timer? _autoLockTimer;

  /// How long the app may sit in the background before it re-locks.
  static const autoLockAfter = Duration(seconds: 60);

  /// Determines whether this device already has a wrapped vault key.
  Future<void> init() async {
    try {
      emit(
        await _keystore.hasVaultKey()
            ? const LockLocked()
            : const LockUninitialized(),
      );
    } on KeystoreException catch (e) {
      emit(LockLocked(reason: e.message));
    }
  }

  /// First run: generate a vault key and wrap it under a new Keystore key.
  /// Leaves the vault unlocked, since the user just proved presence by
  /// installing and opening the app and has nothing to protect yet.
  Future<void> createVault() async {
    if (state is LockUnlocking) return;
    emit(const LockUnlocking());
    try {
      emit(
        LockUnlocked(
          await _keystore.createVaultKey(
            title: 'Create your vault',
            subtitle: 'Confirm it is you, so only you can open it later',
          ),
        ),
      );
    } on KeystoreException catch (e) {
      emit(_failureState(e));
    }
  }

  Future<void> unlock() async {
    if (state is LockUnlocking) return;
    emit(const LockUnlocking());

    try {
      final key = await _keystore.unlockVaultKey(
        title: 'Unlock Passwordzzz',
        subtitle: 'Your vault is encrypted on this device',
      );
      emit(LockUnlocked(key));
    } on KeystoreException catch (e) {
      emit(_failureState(e));
    }
  }

  AppLockState _failureState(KeystoreException e) => switch (e.failure) {
    // Dismissing the prompt is not an error; show no message.
    KeystoreFailure.cancelled => const LockLocked(),
    KeystoreFailure.notSetUp => const LockLocked(
      reason:
          'Passwordzzz needs a screen lock. Add a PIN, pattern, or fingerprint '
          'in your device settings, then try again.',
    ),
    KeystoreFailure.lockedOut => const LockLocked(
      reason: 'Too many attempts. Wait a moment and try again.',
    ),
    KeystoreFailure.lockedOutPermanent => const LockLocked(
      reason:
          'Too many attempts. Unlock your device with its PIN or password, '
          'then reopen Passwordzzz.',
    ),
    KeystoreFailure.keyInvalidated => LockUnrecoverable(e.message),
    KeystoreFailure.noVault => const LockUninitialized(),
    KeystoreFailure.failed => LockLocked(reason: e.message),
  };

  /// Zeroes the vault key and returns to [LockLocked].
  void lock({String? reason}) {
    _autoLockTimer?.cancel();
    _autoLockTimer = null;

    final current = state;
    if (current is LockUnlocked) {
      // Overwrite the key material before dropping the reference. Dart cannot
      // guarantee this is the only copy, but it removes the value from the
      // live object rather than waiting on the GC.
      current.vaultKey.destroy();
    }
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
    final current = state;
    if (current is LockUnlocked) current.vaultKey.destroy();
    WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }
}

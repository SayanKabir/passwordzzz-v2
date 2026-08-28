import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passwordzzz_v2/core/crypto/keystore_channel.dart';
import 'package:passwordzzz_v2/core/crypto/vault_key.dart';
import 'package:passwordzzz_v2/features/unlock/bloc/app_lock_cubit.dart';
import 'package:passwordzzz_v2/features/unlock/bloc/app_lock_state.dart';

/// Scriptable stand-in so lock behaviour can be tested without a platform
/// channel, a Keystore, or a real fingerprint sensor.
class FakeKeystore implements KeystoreChannel {
  FakeKeystore({this.vaultExists = true, this.failure});

  bool vaultExists;
  KeystoreFailure? failure;
  int unlockCalls = 0;

  /// The key handed out, kept so tests can assert it was zeroed.
  VaultKey? issued;

  @override
  Future<bool> hasVaultKey() async => vaultExists;

  @override
  Future<AuthAvailability> canAuthenticate() async => AuthAvailability.available;

  @override
  Future<VaultKey> createVaultKey({
    required String title,
    required String subtitle,
  }) async {
    if (failure != null) throw KeystoreException(failure!, 'fake');
    vaultExists = true;
    return issued = VaultKey(Uint8List(VaultKey.length)..fillRange(0, 32, 3));
  }

  @override
  Future<VaultKey> unlockVaultKey({
    required String title,
    required String subtitle,
  }) async {
    unlockCalls++;
    if (failure != null) throw KeystoreException(failure!, 'fake message');
    return issued = VaultKey(Uint8List(VaultKey.length)..fillRange(0, 32, 3));
  }

  @override
  Future<void> deleteVaultKey() async => vaultExists = false;
}

void main() {
  // AppLockCubit registers a WidgetsBindingObserver in its constructor.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLockCubit', () {
    test('starts in LockChecking before init runs', () {
      final cubit = AppLockCubit(keystore: FakeKeystore());
      addTearDown(cubit.close);
      expect(cubit.state, isA<LockChecking>());
    });

    test('init reports Locked when a wrapped key exists', () async {
      final cubit = AppLockCubit(keystore: FakeKeystore(vaultExists: true));
      addTearDown(cubit.close);
      await cubit.init();
      expect(cubit.state, isA<LockLocked>());
    });

    test('init reports Uninitialized on a fresh install', () async {
      final cubit = AppLockCubit(keystore: FakeKeystore(vaultExists: false));
      addTearDown(cubit.close);
      await cubit.init();
      expect(cubit.state, isA<LockUninitialized>());
    });

    test('unlock transitions through Unlocking to Unlocked', () async {
      final cubit = AppLockCubit(keystore: FakeKeystore());
      addTearDown(cubit.close);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<LockUnlocking>(), isA<LockUnlocked>()]),
      );
      await cubit.unlock();
      await expectation;
    });

    test('concurrent unlocks raise only one prompt', () async {
      // Two prompts stacked on one another is a native-side mess and looks
      // broken to the user.
      final keystore = FakeKeystore();
      final cubit = AppLockCubit(keystore: keystore);
      addTearDown(cubit.close);

      await Future.wait([cubit.unlock(), cubit.unlock()]);

      expect(keystore.unlockCalls, 1);
      expect(cubit.state, isA<LockUnlocked>());
    });

    test('lock() zeroes the vault key', () async {
      // The whole point of holding the key in a mutable buffer.
      final keystore = FakeKeystore();
      final cubit = AppLockCubit(keystore: keystore);
      addTearDown(cubit.close);

      await cubit.unlock();
      final key = (cubit.state as LockUnlocked).vaultKey;
      expect(key.isDestroyed, isFalse);

      cubit.lock();

      expect(key.isDestroyed, isTrue);
      expect(cubit.state, isA<LockLocked>());
    });

    test('close() zeroes the vault key too', () async {
      final cubit = AppLockCubit(keystore: FakeKeystore());
      await cubit.unlock();
      final key = (cubit.state as LockUnlocked).vaultKey;

      await cubit.close();

      expect(key.isDestroyed, isTrue);
    });

    test('a cancelled prompt returns to Locked with no message', () async {
      final cubit = AppLockCubit(
        keystore: FakeKeystore(failure: KeystoreFailure.cancelled),
      );
      addTearDown(cubit.close);

      await cubit.unlock();

      expect(cubit.state, isA<LockLocked>());
      expect((cubit.state as LockLocked).reason, isNull);
    });

    test('no screen lock configured explains how to fix it', () async {
      final cubit = AppLockCubit(
        keystore: FakeKeystore(failure: KeystoreFailure.notSetUp),
      );
      addTearDown(cubit.close);

      await cubit.unlock();

      expect((cubit.state as LockLocked).reason, contains('screen lock'));
    });

    test('an invalidated key becomes Unrecoverable, not Locked', () async {
      // Retrying the prompt cannot help once biometric enrolment changed, so
      // the UI has to offer recovery instead of another attempt.
      final cubit = AppLockCubit(
        keystore: FakeKeystore(failure: KeystoreFailure.keyInvalidated),
      );
      addTearDown(cubit.close);

      await cubit.unlock();

      expect(cubit.state, isA<LockUnrecoverable>());
    });

    test('a failed unlock never reaches LockUnlocked', () async {
      for (final f in [
        KeystoreFailure.cancelled,
        KeystoreFailure.notSetUp,
        KeystoreFailure.lockedOut,
        KeystoreFailure.lockedOutPermanent,
        KeystoreFailure.keyInvalidated,
        KeystoreFailure.failed,
      ]) {
        final cubit = AppLockCubit(keystore: FakeKeystore(failure: f));
        await cubit.unlock();
        expect(cubit.state, isNot(isA<LockUnlocked>()), reason: '$f');
        await cubit.close();
      }
    });

    test('backgrounding while unlocked defers locking to the timer', () async {
      final cubit = AppLockCubit(keystore: FakeKeystore());
      addTearDown(cubit.close);
      await cubit.unlock();

      cubit.didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(AppLockCubit.autoLockAfter, const Duration(seconds: 60));
      expect(
        cubit.state,
        isA<LockUnlocked>(),
        reason: 'lock is scheduled, not immediate',
      );
    });

    test('returning to the foreground cancels a pending auto-lock', () async {
      final cubit = AppLockCubit(keystore: FakeKeystore());
      addTearDown(cubit.close);
      await cubit.unlock();

      cubit.didChangeAppLifecycleState(AppLifecycleState.paused);
      cubit.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(cubit.state, isA<LockUnlocked>());
    });
  });
}

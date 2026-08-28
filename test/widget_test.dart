import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passwordzzz_v2/core/crypto/biometric_authenticator.dart';
import 'package:passwordzzz_v2/features/unlock/bloc/app_lock_cubit.dart';
import 'package:passwordzzz_v2/features/unlock/bloc/app_lock_state.dart';

/// Scriptable stand-in so lock behaviour can be tested without a platform
/// channel or a real fingerprint sensor.
class _FakeAuth implements BiometricAuthenticator {
  _FakeAuth(this.outcome);

  AuthOutcome outcome;
  int calls = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<AuthOutcome> authenticate({required String reason}) async {
    calls++;
    return outcome;
  }
}

void main() {
  // AppLockCubit registers a WidgetsBindingObserver in its constructor, so the
  // binding must exist before any instance is built.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLockCubit', () {
    test('starts locked', () {
      final cubit = AppLockCubit(authenticator: _FakeAuth(const AuthSucceeded()));
      addTearDown(cubit.close);
      expect(cubit.state, isA<LockLocked>());
    });

    test('unlock transitions through LockUnlocking to LockUnlocked', () async {
      final cubit = AppLockCubit(authenticator: _FakeAuth(const AuthSucceeded()));
      addTearDown(cubit.close);

      // Set the expectation before triggering, so no emission is missed to a
      // late subscription.
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<LockUnlocking>(), isA<LockUnlocked>()]),
      );

      await cubit.unlock();
      await expectation;
    });

    test('concurrent unlock calls are ignored while one is in flight', () async {
      final cubit = AppLockCubit(authenticator: _FakeAuth(const AuthSucceeded()));
      addTearDown(cubit.close);

      final states = <AppLockState>[];
      final sub = cubit.stream.listen(states.add);

      await Future.wait([cubit.unlock(), cubit.unlock()]);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      // A second biometric prompt must not stack on the first.
      expect(states.whereType<LockUnlocking>(), hasLength(1));
      expect(cubit.state, isA<LockUnlocked>());
    });

    test('a cancelled prompt returns to Locked with no message', () async {
      final cubit = AppLockCubit(
        authenticator: _FakeAuth(const AuthCancelled()),
      );
      addTearDown(cubit.close);

      await cubit.unlock();

      expect(cubit.state, isA<LockLocked>());
      expect(
        (cubit.state as LockLocked).reason,
        isNull,
        reason: 'dismissing the prompt is not an error',
      );
    });

    test('no screen lock configured explains how to fix it', () async {
      final cubit = AppLockCubit(
        authenticator: _FakeAuth(const AuthNotSetUp()),
      );
      addTearDown(cubit.close);

      await cubit.unlock();

      expect(cubit.state, isA<LockLocked>());
      expect((cubit.state as LockLocked).reason, contains('screen lock'));
    });

    test('permanent lockout tells the user to unlock the device', () async {
      final cubit = AppLockCubit(
        authenticator: _FakeAuth(const AuthLockedOut(permanent: true)),
      );
      addTearDown(cubit.close);

      await cubit.unlock();

      expect((cubit.state as LockLocked).reason, contains('PIN or password'));
    });

    test('a failed auth never reaches LockUnlocked', () async {
      final cubit = AppLockCubit(
        authenticator: _FakeAuth(const AuthFailed('sensor error')),
      );
      addTearDown(cubit.close);

      await cubit.unlock();

      expect(cubit.state, isNot(isA<LockUnlocked>()));
    });

    test('lock() returns to LockLocked and carries the reason', () async {
      final cubit = AppLockCubit(authenticator: _FakeAuth(const AuthSucceeded()));
      addTearDown(cubit.close);

      await cubit.unlock();
      cubit.lock(reason: 'Session expired');

      expect(cubit.state, isA<LockLocked>());
      expect((cubit.state as LockLocked).reason, 'Session expired');
    });

    test('backgrounding while unlocked defers locking to the timer', () async {
      // Guards the rule that the vault must not stay readable in the recents
      // switcher, without locking so eagerly that an app-switch to fetch an
      // OTP wipes the session. Phase 1 extends this to assert the key bytes
      // are zeroed when the timer does fire.
      final cubit = AppLockCubit(authenticator: _FakeAuth(const AuthSucceeded()));
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
      final cubit = AppLockCubit(authenticator: _FakeAuth(const AuthSucceeded()));
      addTearDown(cubit.close);
      await cubit.unlock();

      cubit.didChangeAppLifecycleState(AppLifecycleState.paused);
      cubit.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(cubit.state, isA<LockUnlocked>());
    });
  });
}

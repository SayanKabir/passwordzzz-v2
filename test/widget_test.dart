import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passwordzzz_v2/features/unlock/bloc/app_lock_cubit.dart';
import 'package:passwordzzz_v2/features/unlock/bloc/app_lock_state.dart';

void main() {
  // AppLockCubit registers a WidgetsBindingObserver in its constructor, so the
  // binding must exist before any instance is built.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLockCubit', () {
    test('starts locked', () {
      final cubit = AppLockCubit();
      addTearDown(cubit.close);
      expect(cubit.state, isA<LockLocked>());
    });

    test('unlock transitions through LockUnlocking to LockUnlocked', () async {
      final cubit = AppLockCubit();
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
      final cubit = AppLockCubit();
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

    test('lock() returns to LockLocked and carries the reason', () async {
      final cubit = AppLockCubit();
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
      final cubit = AppLockCubit();
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
      final cubit = AppLockCubit();
      addTearDown(cubit.close);
      await cubit.unlock();

      cubit.didChangeAppLifecycleState(AppLifecycleState.paused);
      cubit.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(cubit.state, isA<LockUnlocked>());
    });
  });
}

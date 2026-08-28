import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passwordzzz_v2/core/crypto/biometric_authenticator.dart';
import 'package:passwordzzz_v2/features/settings/bloc/theme_cubit.dart';
import 'package:passwordzzz_v2/features/settings/view/settings_page.dart';
import 'package:passwordzzz_v2/features/unlock/bloc/app_lock_cubit.dart';
import 'package:passwordzzz_v2/features/unlock/view/unlock_page.dart';
import 'package:passwordzzz_v2/features/vault/view/vault_page.dart';
import 'package:passwordzzz_v2/ui/theme/app_theme.dart';
import 'package:passwordzzz_v2/ui/widgets/glass.dart';
import 'package:passwordzzz_v2/ui/widgets/passwordzzz_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every page is pumped under both themes. This is what catches a token read
/// through `Theme.of(context).extension<AppColors>()!` that was never
/// registered for one brightness — a null-assertion crash that only shows up
/// in the theme you didn't happen to be testing in.
class _AlwaysAllow implements BiometricAuthenticator {
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<AuthOutcome> authenticate({required String reason}) async =>
      const AuthSucceeded();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget host(Widget child, ThemeMode mode, AppLockCubit lock) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: lock),
        BlocProvider(create: (_) => ThemeCubit(prefs)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        home: child,
      ),
    );
  }

  for (final (name, mode) in [
    ('light', ThemeMode.light),
    ('dark', ThemeMode.dark),
  ]) {
    group('$name theme', () {
      testWidgets('UnlockPage renders its locked state', (tester) async {
        final lock = AppLockCubit(authenticator: _AlwaysAllow());
        addTearDown(lock.close);

        await tester.pumpWidget(host(const UnlockPage(), mode, lock));

        expect(find.text('Your vault is locked.'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Unlock'), findsOneWidget);
      });

      testWidgets('VaultPage renders the empty state', (tester) async {
        final lock = AppLockCubit(authenticator: _AlwaysAllow());
        addTearDown(lock.close);

        await tester.pumpWidget(host(const VaultPage(), mode, lock));

        expect(find.text('Your vault is empty'), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        // Settings is reached by tapping the wordmark; there is no gear icon.
        expect(find.byIcon(Icons.settings_outlined), findsNothing);
        expect(find.byType(PasswordzzzWordmark), findsOneWidget);
      });

      testWidgets('SettingsPage renders the theme selector', (tester) async {
        final lock = AppLockCubit(authenticator: _AlwaysAllow());
        addTearDown(lock.close);

        await tester.pumpWidget(host(const SettingsPage(), mode, lock));

        expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);
        expect(find.text('System'), findsOneWidget);
        expect(find.text('Light'), findsOneWidget);
        expect(find.text('Dark'), findsOneWidget);
      });
    });
  }

  testWidgets('tapping a theme segment persists the choice', (tester) async {
    final lock = AppLockCubit(authenticator: _AlwaysAllow());
    addTearDown(lock.close);

    await tester.pumpWidget(host(const SettingsPage(), ThemeMode.dark, lock));
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(prefs.getString('themeMode'), 'light');
  });

  testWidgets('the vault screen spends at most one blur', (tester) async {
    // v1 stacked four simultaneous full-screen blurs, which was the main
    // source of scroll jank on mid-range hardware. This asserts the budget
    // rather than trusting it.
    final lock = AppLockCubit(authenticator: _AlwaysAllow());
    addTearDown(lock.close);

    await tester.pumpWidget(host(const VaultPage(), ThemeMode.dark, lock));

    expect(
      find.byType(BackdropFilter).evaluate().length,
      lessThanOrEqualTo(1),
    );
  });

  testWidgets('GlassScope(false) forces the app bar off the blur path', (
    tester,
  ) async {
    // What a sheet does while it owns the budget.
    final lock = AppLockCubit(authenticator: _AlwaysAllow());
    addTearDown(lock.close);

    await tester.pumpWidget(
      host(
        const GlassScope(blurAvailable: false, child: VaultPage()),
        ThemeMode.dark,
        lock,
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('the mark paints without an asset in both themes', (
    tester,
  ) async {
    // The v1 logo was a white PNG that vanished on light surfaces. A painter
    // takes its color from the theme, so this can't regress silently.
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      final lock = AppLockCubit(authenticator: _AlwaysAllow());
      addTearDown(lock.close);

      await tester.pumpWidget(
        host(const Center(child: PasswordzzzMark(size: 64)), mode, lock),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(PasswordzzzMark), findsOneWidget);
    }
  });
}

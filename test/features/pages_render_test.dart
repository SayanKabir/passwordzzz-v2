import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passwordzzz_v2/features/settings/bloc/theme_cubit.dart';
import 'package:passwordzzz_v2/features/settings/view/settings_page.dart';
import 'package:passwordzzz_v2/features/unlock/bloc/app_lock_cubit.dart';
import 'package:passwordzzz_v2/features/unlock/view/unlock_page.dart';
import 'package:passwordzzz_v2/features/vault/view/vault_page.dart';
import 'package:passwordzzz_v2/ui/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every page is pumped under both themes. This is what catches a token read
/// through `Theme.of(context).extension<AppColors>()!` that was never
/// registered for one brightness — a null-assertion crash that only shows up
/// in the theme you didn't happen to be testing in.
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
        final lock = AppLockCubit();
        addTearDown(lock.close);

        await tester.pumpWidget(host(const UnlockPage(), mode, lock));

        expect(find.text('Your vault is locked.'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Unlock'), findsOneWidget);
      });

      testWidgets('VaultPage renders the empty state', (tester) async {
        final lock = AppLockCubit();
        addTearDown(lock.close);

        await tester.pumpWidget(host(const VaultPage(), mode, lock));

        expect(find.text('Your vault is empty'), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      });

      testWidgets('SettingsPage renders the theme selector', (tester) async {
        final lock = AppLockCubit();
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
    final lock = AppLockCubit();
    addTearDown(lock.close);

    await tester.pumpWidget(host(const SettingsPage(), ThemeMode.dark, lock));
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(prefs.getString('themeMode'), 'light');
  });

  testWidgets('the vault app bar has exactly one BackdropFilter', (
    tester,
  ) async {
    // v1 stacked four simultaneous full-screen blurs, which was the main
    // source of scroll jank. This asserts the budget rather than trusting it.
    final lock = AppLockCubit();
    addTearDown(lock.close);

    await tester.pumpWidget(host(const VaultPage(), ThemeMode.dark, lock));

    expect(
      find.byType(BackdropFilter).evaluate().length,
      lessThanOrEqualTo(1),
    );
  });
}

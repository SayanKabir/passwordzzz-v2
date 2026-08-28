import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:passwordzzz_v2/core/crypto/keystore_channel.dart';

import '../widget_test.dart' show FakeKeystore;
import 'package:passwordzzz_v2/features/settings/bloc/theme_cubit.dart';
import 'package:passwordzzz_v2/features/settings/view/settings_page.dart';
import 'package:passwordzzz_v2/features/unlock/bloc/app_lock_cubit.dart';
import 'package:passwordzzz_v2/features/unlock/view/unlock_page.dart';
import 'package:passwordzzz_v2/features/vault/view/vault_page.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:passwordzzz_v2/core/crypto/vault_key.dart';
import 'package:passwordzzz_v2/data/models/vault_entry.dart';
import 'package:passwordzzz_v2/data/repository/vault_repository.dart';
import 'package:passwordzzz_v2/features/vault/bloc/vault_bloc.dart';
import 'package:passwordzzz_v2/ui/theme/app_theme.dart';
import 'package:passwordzzz_v2/ui/widgets/glass.dart';
import 'package:passwordzzz_v2/ui/widgets/passwordzzz_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every page is pumped under both themes. This is what catches a token read
/// through `Theme.of(context).extension<AppColors>()!` that was never
/// registered for one brightness — a null-assertion crash that only shows up
/// in the theme you didn't happen to be testing in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late _FakeVault vault;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    vault = _FakeVault();
  });

  tearDown(() => vault.dispose());

  /// Hands the bloc a key and lets the drift stream deliver its first (empty)
  /// snapshot, which is what moves VaultPage out of its loading state.
  Future<void> openVault(WidgetTester tester) async {
    final ctx = tester.element(find.byType(VaultPage));
    ctx.read<VaultBloc>().add(
      VaultOpened(VaultKey(Uint8List(VaultKey.length))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Widget host(Widget child, ThemeMode mode, AppLockCubit lock) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: lock),
        BlocProvider(create: (_) => ThemeCubit(prefs)),
        BlocProvider(create: (_) => VaultBloc(vault)),
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
        final lock = AppLockCubit(keystore: FakeKeystore(vaultExists: true));
        addTearDown(lock.close);
        await lock.init();

        await tester.pumpWidget(host(const UnlockPage(), mode, lock));

        expect(find.text('Your vault is locked.'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Unlock'), findsOneWidget);
      });

      testWidgets('UnlockPage offers setup on a fresh install', (tester) async {
        final lock = AppLockCubit(keystore: FakeKeystore(vaultExists: false));
        addTearDown(lock.close);
        await lock.init();

        await tester.pumpWidget(host(const UnlockPage(), mode, lock));

        expect(find.widgetWithText(FilledButton, 'Create vault'), findsOneWidget);
        expect(find.textContaining('never leaves it'), findsOneWidget);
      });

      testWidgets('UnlockPage offers recovery, not a retry, when the key is '
          'invalidated', (tester) async {
        final lock = AppLockCubit(
          keystore: FakeKeystore(failure: KeystoreFailure.keyInvalidated),
        );
        addTearDown(lock.close);
        await lock.unlock();

        await tester.pumpWidget(host(const UnlockPage(), mode, lock));

        expect(
          find.widgetWithText(FilledButton, 'Restore with recovery code'),
          findsOneWidget,
        );
        expect(find.widgetWithText(FilledButton, 'Unlock'), findsNothing);
      });

      testWidgets('VaultPage renders the empty state', (tester) async {
        final lock = AppLockCubit(keystore: FakeKeystore());
        addTearDown(lock.close);

        await tester.pumpWidget(host(const VaultPage(), mode, lock));
        // The list is empty only once the vault is open; before that the page
        // is legitimately in its loading state.
        await openVault(tester);

        expect(find.text('Your vault is empty'), findsOneWidget);
        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        // Settings is reached by tapping the wordmark; there is no gear icon.
        expect(find.byIcon(Icons.settings_outlined), findsNothing);
        expect(find.byType(PasswordzzzWordmark), findsOneWidget);
      });

      testWidgets('SettingsPage renders the theme selector', (tester) async {
        final lock = AppLockCubit(keystore: FakeKeystore());
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
    final lock = AppLockCubit(keystore: FakeKeystore());
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
    final lock = AppLockCubit(keystore: FakeKeystore());
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
    final lock = AppLockCubit(keystore: FakeKeystore());
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
      final lock = AppLockCubit(keystore: FakeKeystore());
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

/// In-memory stand-in for [VaultRepository].
///
/// Widget tests used to open a real drift database here. drift leaves a pending
/// timer, which `flutter_test` asserts on before teardown runs, and that wedged
/// the whole file rather than failing one test.
class _FakeVault implements VaultDataSource {
  final _controller = StreamController<List<VaultEntry>>.broadcast();
  final _entries = <VaultEntry>[];

  void dispose() => _controller.close();

  @override
  Stream<List<VaultEntry>> watchEntries(VaultKey key) async* {
    yield List.of(_entries);
    yield* _controller.stream;
  }

  @override
  Future<List<VaultEntry>> loadEntries(VaultKey key) async => List.of(_entries);

  @override
  Future<VaultEntry> create({
    required VaultKey key,
    required String site,
    required String username,
    required String password,
    String notes = '',
    String? totpSecret,
    DateTime? createdAt,
  }) async {
    final now = DateTime.now().toUtc();
    final e = VaultEntry(
      id: 'id-${_entries.length}',
      site: site,
      username: username,
      password: password,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    _entries.add(e);
    _controller.add(List.of(_entries));
    return e;
  }

  @override
  Future<VaultEntry> update({
    required VaultKey key,
    required VaultEntry entry,
  }) async {
    final i = _entries.indexWhere((e) => e.id == entry.id);
    if (i >= 0) _entries[i] = entry;
    _controller.add(List.of(_entries));
    return entry;
  }

  @override
  Future<void> delete(String id) async {
    _entries.removeWhere((e) => e.id == id);
    _controller.add(List.of(_entries));
  }

  @override
  Future<int> importAll({
    required VaultKey key,
    required List<VaultEntry> entries,
  }) async {
    _entries.addAll(entries);
    _controller.add(List.of(_entries));
    return entries.length;
  }
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'features/settings/view/settings_page.dart';
import 'features/unlock/bloc/app_lock_cubit.dart';
import 'features/unlock/bloc/app_lock_state.dart';
import 'features/settings/view/transfer_page.dart';
import 'features/unlock/view/unlock_page.dart';
import 'features/vault/view/vault_page.dart';

abstract final class Routes {
  static const unlock = '/unlock';
  static const vault = '/';
  static const settings = '/settings';
  static const transfer = '/settings/transfer';
}

/// Router with a lock-state guard.
///
/// This replaces v1's `auth_gate.dart`, which was written but never imported —
/// `main.dart` went straight to the login screen, which never navigated, so the
/// manager screen was unreachable. Here the guard is the only way in, so it
/// cannot be bypassed by forgetting to wire it up.
GoRouter buildRouter(AppLockCubit lock) {
  return GoRouter(
    initialLocation: Routes.vault,
    refreshListenable: _CubitRefresh(lock.stream),
    redirect: (context, state) {
      // Anything that is not an in-memory vault key belongs on the unlock
      // screen — including first run and the unrecoverable case, both of which
      // that screen handles.
      final locked = lock.state is! LockUnlocked;
      final atUnlock = state.matchedLocation == Routes.unlock;

      if (locked && !atUnlock) return Routes.unlock;
      if (!locked && atUnlock) return Routes.vault;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.unlock,
        builder: (context, state) => const UnlockPage(),
      ),
      GoRoute(
        path: Routes.vault,
        builder: (context, state) => const VaultPage(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsPage(),
            routes: [
              GoRoute(
                path: 'transfer',
                builder: (context, state) => const TransferPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Bridges a bloc [Stream] to the [Listenable] go_router wants.
class _CubitRefresh extends ChangeNotifier {
  _CubitRefresh(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

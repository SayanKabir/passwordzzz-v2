import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_router.dart';
import 'core/di/service_locator.dart';
import 'core/util/app_bloc_observer.dart';
import 'data/repository/vault_repository.dart';
import 'features/settings/bloc/theme_cubit.dart';
import 'features/unlock/bloc/app_lock_cubit.dart';
import 'features/unlock/bloc/app_lock_state.dart';
import 'features/vault/bloc/vault_bloc.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();
  await configureDependencies();
  runApp(const PasswordzzzApp());
}

class PasswordzzzApp extends StatefulWidget {
  const PasswordzzzApp({super.key});

  @override
  State<PasswordzzzApp> createState() => _PasswordzzzAppState();
}

class _PasswordzzzAppState extends State<PasswordzzzApp> {
  late final AppLockCubit _lock = AppLockCubit()..init();
  late final _router = buildRouter(_lock);

  @override
  void dispose() {
    _lock.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _lock),
        BlocProvider(create: (_) => ThemeCubit(getIt<SharedPreferences>())),
        BlocProvider(create: (_) => VaultBloc(getIt<VaultRepository>())),
      ],
      // The vault key is handed to VaultBloc only when the lock opens, so the
      // bloc can never hold a key across a lock. On lock the drift stream is
      // dropped and the decrypted list goes with it.
      child: BlocListener<AppLockCubit, AppLockState>(
        listenWhen: (a, b) => b is LockUnlocked,
        listener: (context, state) {
          if (state is LockUnlocked) {
            context.read<VaultBloc>().add(VaultOpened(state.vaultKey));
          }
        },
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: 'Passwordzzz',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: themeMode,
              routerConfig: _router,
            );
          },
        ),
      ),
    );
  }
}

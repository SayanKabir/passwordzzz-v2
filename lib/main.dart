import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_router.dart';
import 'core/di/service_locator.dart';
import 'core/util/app_bloc_observer.dart';
import 'features/settings/bloc/theme_cubit.dart';
import 'features/unlock/bloc/app_lock_cubit.dart';
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
  late final AppLockCubit _lock = AppLockCubit();
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
      ],
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
    );
  }
}

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/app_database.dart';
import '../../data/repository/vault_repository.dart';

final getIt = GetIt.instance;

/// Registers long-lived singletons.
///
/// Blocs are NOT registered here — they are created by `BlocProvider` so their
/// lifetime is tied to the widget tree and `close()` runs deterministically.
/// get_it holds only what blocs depend on: repositories, clients, platform
/// wrappers.
Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  final db = AppDatabase();
  getIt.registerSingleton<AppDatabase>(db);
  getIt.registerSingleton<VaultRepository>(VaultRepository(database: db));

  // Phase 3 registers SupabaseClient + SyncService.
}

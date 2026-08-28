import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

/// Registers long-lived singletons. Blocs are NOT registered here — they are
/// created by `BlocProvider` so their lifetime is tied to the widget tree and
/// `close()` runs deterministically. get_it holds only the things blocs depend
/// on: repositories, clients, platform wrappers.
Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Phase 1 registers CryptoService + KeystoreChannel here.
  // Phase 2 registers AppDatabase + VaultRepository.
  // Phase 3 registers SupabaseClient + SyncService.
}

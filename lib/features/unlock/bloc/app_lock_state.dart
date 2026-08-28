import 'package:equatable/equatable.dart';

/// Lock state for the whole app.
///
/// Sealed so the router's redirect guard and every `switch` over it are
/// exhaustive — a new state cannot be added without the compiler pointing at
/// every place that has to handle it. This is the reason the plan chose BLoC:
/// a mutable `ChangeNotifier` makes it easy to leave the vault key readable in
/// a state that should not hold it.
sealed class AppLockState extends Equatable {
  const AppLockState();

  @override
  List<Object?> get props => const [];
}

/// No vault exists yet on this device — first run.
final class LockUninitialized extends AppLockState {
  const LockUninitialized();
}

/// A vault exists but the key is not in memory.
final class LockLocked extends AppLockState {
  const LockLocked({this.reason});

  /// Populated after a failed or cancelled authentication attempt.
  final String? reason;

  @override
  List<Object?> get props => [reason];
}

/// Authentication is in flight (biometric prompt showing).
final class LockUnlocking extends AppLockState {
  const LockUnlocking();
}

/// Vault key is in memory and the vault is readable.
///
/// Phase 1 adds the key material to this state. It is deliberately not part of
/// [props] — equality must never depend on secret bytes, and `Equatable`'s
/// generated `toString` would otherwise print them.
final class LockUnlocked extends AppLockState {
  const LockUnlocked();
}

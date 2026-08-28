import 'package:equatable/equatable.dart';

import '../../../core/crypto/vault_key.dart';

/// Lock state for the whole app.
///
/// Sealed so the router's redirect guard and every switch over it are
/// exhaustive — a new state cannot be added without the compiler pointing at
/// each place that must handle it.
sealed class AppLockState extends Equatable {
  const AppLockState();

  @override
  List<Object?> get props => const [];
}

/// Startup, before we know whether a vault exists on this device.
final class LockChecking extends AppLockState {
  const LockChecking();
}

/// No vault key on this device yet — first run.
final class LockUninitialized extends AppLockState {
  const LockUninitialized();
}

/// A wrapped vault key exists but is not in memory.
final class LockLocked extends AppLockState {
  const LockLocked({this.reason});

  /// Populated after a failed attempt. Null after a plain cancel.
  final String? reason;

  @override
  List<Object?> get props => [reason];
}

/// The system prompt is showing.
final class LockUnlocking extends AppLockState {
  const LockUnlocking();
}

/// The Keystore key was invalidated by a biometric enrolment change. The
/// wrapped key is gone for good on this device; only the recovery code can
/// bring the vault back. Distinct from [LockLocked] because retrying the prompt
/// is pointless and the UI must offer recovery instead.
final class LockUnrecoverable extends AppLockState {
  const LockUnrecoverable(this.reason);
  final String reason;

  @override
  List<Object?> get props => [reason];
}

/// The vault key is in memory and records can be decrypted.
///
/// [vaultKey] is deliberately excluded from [props]: equality must never depend
/// on secret bytes, and Equatable's generated `toString` would otherwise print
/// them into any log that dumps a state. [VaultKey] redacts its own toString
/// for the same reason.
final class LockUnlocked extends AppLockState {
  const LockUnlocked(this.vaultKey);

  final VaultKey vaultKey;

  @override
  List<Object?> get props => const [];
}

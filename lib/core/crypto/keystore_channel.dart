import 'package:flutter/services.dart';

import 'vault_key.dart';

/// Why an unlock attempt did not produce a key.
enum KeystoreFailure {
  /// The user dismissed the prompt. Not an error.
  cancelled,

  /// No biometric enrolled and no device credential set.
  notSetUp,

  /// Too many failed attempts; temporary.
  lockedOut,

  /// Too many failed attempts; needs a full device unlock.
  lockedOutPermanent,

  /// Biometric enrolment changed, so the Keystore key was invalidated. The
  /// wrapped vault key is unrecoverable on this device — recovery code only.
  keyInvalidated,

  /// No wrapped key exists yet.
  noVault,

  /// Anything else.
  failed,
}

class KeystoreException implements Exception {
  KeystoreException(this.failure, this.message);
  final KeystoreFailure failure;
  final String message;

  @override
  String toString() => 'KeystoreException($failure): $message';
}

/// Availability of a credential that could authorise an unwrap.
enum AuthAvailability { available, notEnrolled, noHardware, unavailable }

/// Dart side of the `passwordzzz/keystore` channel.
///
/// Every method maps one-to-one onto [VaultKeystore] in Kotlin. The prompt and
/// the unwrap happen together on the native side because the Keystore cipher is
/// bound to the prompt via a CryptoObject — splitting them would break exactly
/// the property that makes the binding worth having.
abstract interface class KeystoreChannel {
  Future<bool> hasVaultKey();
  Future<AuthAvailability> canAuthenticate();

  /// Generates and wraps a new vault key. First run only.
  ///
  /// Prompts, exactly as [unlockVaultKey] does: the KEK requires authentication
  /// for every operation, encryption included.
  Future<VaultKey> createVaultKey({
    required String title,
    required String subtitle,
  });

  /// Prompts, then unwraps. Throws [KeystoreException] on any non-success.
  Future<VaultKey> unlockVaultKey({
    required String title,
    required String subtitle,
  });

  Future<void> deleteVaultKey();
}

class MethodChannelKeystore implements KeystoreChannel {
  MethodChannelKeystore([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('passwordzzz/keystore');

  final MethodChannel _channel;

  @override
  Future<bool> hasVaultKey() async =>
      await _channel.invokeMethod<bool>('hasVaultKey') ?? false;

  @override
  Future<AuthAvailability> canAuthenticate() async {
    final v = await _channel.invokeMethod<String>('canAuthenticate');
    return switch (v) {
      'available' => AuthAvailability.available,
      'not_enrolled' => AuthAvailability.notEnrolled,
      'no_hardware' => AuthAvailability.noHardware,
      _ => AuthAvailability.unavailable,
    };
  }

  @override
  Future<VaultKey> createVaultKey({
    required String title,
    required String subtitle,
  }) async {
    try {
      final r = await _channel.invokeMapMethod<String, dynamic>(
        'createVaultKey',
        {'title': title, 'subtitle': subtitle},
      );
      final bytes = r?['vaultKey'] as Uint8List?;
      if (bytes == null) {
        throw KeystoreException(KeystoreFailure.failed, 'No key returned.');
      }
      return VaultKey(bytes);
    } on PlatformException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<VaultKey> unlockVaultKey({
    required String title,
    required String subtitle,
  }) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('unlockVaultKey', {
        'title': title,
        'subtitle': subtitle,
      });
      if (bytes == null) {
        throw KeystoreException(KeystoreFailure.failed, 'No key returned.');
      }
      return VaultKey(bytes);
    } on PlatformException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> deleteVaultKey() => _channel.invokeMethod('deleteVaultKey');

  KeystoreException _map(PlatformException e) {
    final failure = switch (e.code) {
      'cancelled' => KeystoreFailure.cancelled,
      'not_set_up' => KeystoreFailure.notSetUp,
      'locked_out' => KeystoreFailure.lockedOut,
      'locked_out_permanent' => KeystoreFailure.lockedOutPermanent,
      'key_invalidated' => KeystoreFailure.keyInvalidated,
      'no_vault' => KeystoreFailure.noVault,
      _ => KeystoreFailure.failed,
    };
    return KeystoreException(failure, e.message ?? e.code);
  }
}

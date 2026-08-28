import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

/// Outcome of a device-authentication attempt.
///
/// A sealed result rather than a bare bool, because the failure modes need
/// different UI: a cancel is not an error, a lockout is temporary, and "no
/// screen lock configured" is the user's to fix in system settings. v1 called
/// `authenticate()` with no try/catch and no capability pre-check, so on a
/// device with nothing enrolled the tap silently did nothing.
sealed class AuthOutcome {
  const AuthOutcome();
}

final class AuthSucceeded extends AuthOutcome {
  const AuthSucceeded();
}

/// The user dismissed the prompt. Not an error; show no message.
final class AuthCancelled extends AuthOutcome {
  const AuthCancelled();
}

/// Device has no enrolled biometric AND no PIN/pattern/password.
final class AuthNotSetUp extends AuthOutcome {
  const AuthNotSetUp();
}

/// Too many failed attempts. [permanent] means a full device unlock is needed.
final class AuthLockedOut extends AuthOutcome {
  const AuthLockedOut({required this.permanent});
  final bool permanent;
}

final class AuthFailed extends AuthOutcome {
  const AuthFailed(this.message);
  final String message;
}

/// Thin wrapper over `local_auth` so [AppLockCubit] depends on an interface it
/// can fake in tests rather than on a plugin that needs a platform channel.
abstract interface class BiometricAuthenticator {
  Future<AuthOutcome> authenticate({required String reason});

  /// Whether any device credential is available to authenticate with.
  Future<bool> isAvailable();
}

class LocalAuthAuthenticator implements BiometricAuthenticator {
  LocalAuthAuthenticator([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      // isDeviceSupported() covers PIN/pattern/password too, which is what we
      // want — a device with no fingerprint sensor but a PIN can still gate
      // the vault.
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<AuthOutcome> authenticate({required String reason}) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // Device credential is allowed as a fallback: locking a password
          // vault behind biometrics *only* strands anyone whose sensor fails.
          biometricOnly: false,
          // Survives the app being backgrounded by the system prompt itself.
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      return ok ? const AuthSucceeded() : const AuthCancelled();
    } on PlatformException catch (e) {
      return switch (e.code) {
        auth_error.notAvailable ||
        auth_error.notEnrolled ||
        auth_error.passcodeNotSet => const AuthNotSetUp(),
        auth_error.lockedOut => const AuthLockedOut(permanent: false),
        auth_error.permanentlyLockedOut => const AuthLockedOut(permanent: true),
        _ => AuthFailed(e.message ?? 'Authentication failed.'),
      };
    }
  }
}

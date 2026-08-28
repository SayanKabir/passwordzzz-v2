import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:dargon2_flutter/dargon2_flutter.dart';

import 'vault_key.dart';

/// Derives a key-encryption key from the user's recovery code, and wraps the
/// vault key under it.
///
/// This is the lost-phone path. The Keystore wrap is bound to one device; if
/// that device is gone, the only way back into the cloud ciphertext is a secret
/// the user holds. The wrapped copy lives in Supabase, so the KDF has to be
/// expensive enough that possessing that row is not enough to brute-force it.
///
/// Argon2id at 64 MiB / t=3 / p=4 costs roughly a second on a mid-range phone.
/// That is deliberately slow: the recovery code is entered once, and every
/// factor of cost here is a factor an attacker with the database must also pay.
class RecoveryKdf {
  RecoveryKdf({AesGcm? algorithm}) : _algorithm = algorithm ?? AesGcm.with256bits();

  final AesGcm _algorithm;

  /// Versioned so parameters can be raised later without stranding existing
  /// vaults — the stored row carries the parameters it was created with.
  static const params = Argon2Params(
    memoryKiB: 65536,
    iterations: 3,
    parallelism: 4,
  );

  static const saltLength = 16;

  static Uint8List newSalt() {
    final r = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(saltLength, (_) => r.nextInt(256)),
    );
  }

  Future<Uint8List> deriveKek({
    required String recoveryCode,
    required Uint8List salt,
    Argon2Params argon = params,
  }) async {
    final result = await argon2.hashPasswordString(
      _normalize(recoveryCode),
      salt: Salt(salt),
      iterations: argon.iterations,
      memory: argon.memoryKiB,
      parallelism: argon.parallelism,
      length: 32,
      type: Argon2Type.id,
    );
    return Uint8List.fromList(result.rawBytes);
  }

  /// Recovery codes are read off a screen and typed by hand, so case and
  /// spacing must not matter. Normalising here rather than at the call sites
  /// keeps the derivation reproducible.
  static String _normalize(String code) =>
      code.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]+'), ' ');

  Future<WrappedVaultKey> wrap({
    required VaultKey vaultKey,
    required String recoveryCode,
  }) async {
    final salt = newSalt();
    final kek = await deriveKek(recoveryCode: recoveryCode, salt: salt);

    final box = await _algorithm.encrypt(
      vaultKey.bytes,
      secretKey: SecretKey(kek),
      nonce: _algorithm.newNonce(),
    );

    return WrappedVaultKey(
      ciphertext: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
      nonce: Uint8List.fromList(box.nonce),
      salt: salt,
      params: params,
    );
  }

  Future<VaultKey> unwrap({
    required WrappedVaultKey wrapped,
    required String recoveryCode,
  }) async {
    final kek = await deriveKek(
      recoveryCode: recoveryCode,
      salt: wrapped.salt,
      argon: wrapped.params,
    );

    const macLength = 16;
    final split = wrapped.ciphertext.length - macLength;
    final box = SecretBox(
      wrapped.ciphertext.sublist(0, split),
      nonce: wrapped.nonce,
      mac: Mac(wrapped.ciphertext.sublist(split)),
    );

    try {
      final clear = await _algorithm.decrypt(box, secretKey: SecretKey(kek));
      return VaultKey(Uint8List.fromList(clear));
    } on SecretBoxAuthenticationError {
      throw const WrongRecoveryCode();
    }
  }
}

class Argon2Params {
  const Argon2Params({
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
  });

  final int memoryKiB;
  final int iterations;
  final int parallelism;

  Map<String, dynamic> toJson() => {
    'alg': 'argon2id',
    'm': memoryKiB,
    't': iterations,
    'p': parallelism,
  };

  factory Argon2Params.fromJson(Map<String, dynamic> json) => Argon2Params(
    memoryKiB: json['m'] as int,
    iterations: json['t'] as int,
    parallelism: json['p'] as int,
  );
}

class WrappedVaultKey {
  const WrappedVaultKey({
    required this.ciphertext,
    required this.nonce,
    required this.salt,
    required this.params,
  });

  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List salt;
  final Argon2Params params;
}

class WrongRecoveryCode implements Exception {
  const WrongRecoveryCode();

  @override
  String toString() => 'WrongRecoveryCode: that recovery code is not correct.';
}

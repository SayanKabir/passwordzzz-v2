import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography_plus/cryptography_plus.dart';

import 'vault_key.dart';

/// Encrypts one vault record.
///
/// AES-256-GCM, a fresh 96-bit nonce per write, and additional authenticated
/// data binding the record's id and schema version. The AAD is the part worth
/// explaining: without it, ciphertext from record A could be pasted over
/// record B and would still decrypt, so an attacker with write access to the
/// database could swap your bank password onto a site they control. Binding the
/// id makes that substitution fail authentication.
///
/// The whole payload is encrypted, site and username included. The server has
/// no business knowing which sites you have accounts on.
class RecordCodec {
  RecordCodec({AesGcm? algorithm})
    : _algorithm = algorithm ?? AesGcm.with256bits();

  final AesGcm _algorithm;

  static const schemaVersion = 1;
  static const nonceLength = 12;

  /// AAD = "pz" | schemaVersion | recordId. Any change to either field makes
  /// decryption fail rather than silently returning another record's data.
  static List<int> aad(String recordId, int schemaVersion) =>
      utf8.encode('pz:$schemaVersion:$recordId');

  Future<EncryptedRecord> encrypt({
    required VaultKey key,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    final secretKey = SecretKey(key.bytes);
    final box = await _algorithm.encrypt(
      utf8.encode(jsonEncode(payload)),
      secretKey: secretKey,
      nonce: _algorithm.newNonce(),
      aad: aad(recordId, schemaVersion),
    );

    return EncryptedRecord(
      // GCM's tag is appended so the stored blob is self-contained; splitting
      // them across columns just creates a way to store one without the other.
      ciphertext: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
      nonce: Uint8List.fromList(box.nonce),
      schemaVersion: schemaVersion,
    );
  }

  Future<Map<String, dynamic>> decrypt({
    required VaultKey key,
    required String recordId,
    required EncryptedRecord record,
  }) async {
    const macLength = 16;
    if (record.ciphertext.length < macLength) {
      throw const RecordDecryptionFailure('Ciphertext shorter than its tag.');
    }
    final split = record.ciphertext.length - macLength;

    final box = SecretBox(
      record.ciphertext.sublist(0, split),
      nonce: record.nonce,
      mac: Mac(record.ciphertext.sublist(split)),
    );

    try {
      final clear = await _algorithm.decrypt(
        box,
        secretKey: SecretKey(key.bytes),
        aad: aad(recordId, record.schemaVersion),
      );
      return jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
    } on SecretBoxAuthenticationError {
      // Wrong key, tampered ciphertext, or a record moved to another id.
      throw const RecordDecryptionFailure(
        'Record failed authentication. It was tampered with, or belongs to a '
        'different vault.',
      );
    }
  }
}

class EncryptedRecord {
  const EncryptedRecord({
    required this.ciphertext,
    required this.nonce,
    required this.schemaVersion,
  });

  final Uint8List ciphertext;
  final Uint8List nonce;
  final int schemaVersion;
}

class RecordDecryptionFailure implements Exception {
  const RecordDecryptionFailure(this.message);
  final String message;

  @override
  String toString() => 'RecordDecryptionFailure: $message';
}

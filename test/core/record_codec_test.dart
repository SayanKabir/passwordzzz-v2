import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:passwordzzz_v2/core/crypto/record_codec.dart';
import 'package:passwordzzz_v2/core/crypto/vault_key.dart';

VaultKey _key([int fill = 7]) =>
    VaultKey(Uint8List.fromList(List.filled(VaultKey.length, fill)));

void main() {
  final codec = RecordCodec();

  const payload = {
    'site': 'github.com',
    'username': 'sayan',
    'password': 'hunter2',
    'notes': 'work account',
  };

  test('round-trips a payload', () async {
    final key = _key();
    final rec = await codec.encrypt(
      key: key,
      recordId: 'abc',
      payload: payload,
    );
    final out = await codec.decrypt(key: key, recordId: 'abc', record: rec);

    expect(out, payload);
  });

  test('the plaintext password never appears in the ciphertext', () async {
    final rec = await codec.encrypt(
      key: _key(),
      recordId: 'abc',
      payload: payload,
    );
    expect(String.fromCharCodes(rec.ciphertext), isNot(contains('hunter2')));
    expect(String.fromCharCodes(rec.ciphertext), isNot(contains('github')));
  });

  test('every write uses a fresh nonce', () async {
    final key = _key();
    final nonces = <String>{};
    for (var i = 0; i < 500; i++) {
      final rec = await codec.encrypt(
        key: key,
        recordId: 'abc',
        payload: payload,
      );
      expect(rec.nonce, hasLength(RecordCodec.nonceLength));
      nonces.add(rec.nonce.join(','));
    }
    // Nonce reuse under one key is catastrophic for GCM — it leaks the
    // authentication subkey, not just the plaintext.
    expect(nonces, hasLength(500));
  });

  test('a record cannot be replayed under a different id', () async {
    // The substitution attack the AAD exists to stop: an attacker with write
    // access swaps a low-value record's ciphertext onto a high-value one.
    final key = _key();
    final rec = await codec.encrypt(
      key: key,
      recordId: 'low-value',
      payload: payload,
    );

    expect(
      () => codec.decrypt(key: key, recordId: 'bank-account', record: rec),
      throwsA(isA<RecordDecryptionFailure>()),
    );
  });

  test('a flipped ciphertext bit fails authentication', () async {
    final key = _key();
    final rec = await codec.encrypt(
      key: key,
      recordId: 'abc',
      payload: payload,
    );
    final tampered = Uint8List.fromList(rec.ciphertext)..[0] ^= 0x01;

    expect(
      () => codec.decrypt(
        key: key,
        recordId: 'abc',
        record: EncryptedRecord(
          ciphertext: tampered,
          nonce: rec.nonce,
          schemaVersion: rec.schemaVersion,
        ),
      ),
      throwsA(isA<RecordDecryptionFailure>()),
    );
  });

  test('a different vault key cannot read the record', () async {
    final rec = await codec.encrypt(
      key: _key(7),
      recordId: 'abc',
      payload: payload,
    );

    expect(
      () => codec.decrypt(key: _key(9), recordId: 'abc', record: rec),
      throwsA(isA<RecordDecryptionFailure>()),
    );
  });

  test('a truncated blob is rejected rather than crashing', () async {
    expect(
      () => codec.decrypt(
        key: _key(),
        recordId: 'abc',
        record: EncryptedRecord(
          ciphertext: Uint8List.fromList([1, 2, 3]),
          nonce: Uint8List(12),
          schemaVersion: 1,
        ),
      ),
      throwsA(isA<RecordDecryptionFailure>()),
    );
  });
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:passwordzzz_v2/core/crypto/vault_key.dart';

void main() {
  test('rejects a key of the wrong length', () {
    expect(() => VaultKey(Uint8List(16)), throwsArgumentError);
    expect(() => VaultKey(Uint8List(64)), throwsArgumentError);
  });

  test('destroy() zeroes the buffer and blocks further reads', () {
    final bytes = Uint8List.fromList(List.filled(VaultKey.length, 0xAB));
    final key = VaultKey(bytes);

    key.destroy();

    expect(bytes.every((b) => b == 0), isTrue,
        reason: 'the backing buffer must be overwritten, not just dropped');
    expect(key.isDestroyed, isTrue);
    expect(() => key.bytes, throwsStateError);
  });

  test('destroy() is idempotent', () {
    final key = VaultKey(Uint8List(VaultKey.length));
    key.destroy();
    expect(key.destroy, returnsNormally);
  });

  test('toString never reveals key material', () {
    final key = VaultKey(Uint8List.fromList(List.filled(VaultKey.length, 0xAB)));
    expect(key.toString(), isNot(contains('171')));
    expect(key.toString(), isNot(contains('AB')));
    expect(key.toString(), 'VaultKey(live)');
  });
}

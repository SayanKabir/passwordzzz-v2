import 'dart:typed_data';

/// Holds the 256-bit vault key while the vault is unlocked.
///
/// Mutable so [destroy] can overwrite the bytes. Dart gives no guarantee the
/// zeroed buffer is the only copy — the GC may have moved it — but overwriting
/// removes the value from the live object and shortens the window in which a
/// heap dump exposes it. That is worth doing even though it is not absolute.
///
/// Deliberately not `Equatable` and with a redacted [toString]: bloc states
/// carry this, and `Equatable`'s generated `toString` would print the key into
/// any log that dumps a state.
class VaultKey {
  VaultKey(Uint8List bytes) : _bytes = bytes {
    if (bytes.length != length) {
      throw ArgumentError('Vault key must be $length bytes, got ${bytes.length}');
    }
  }

  static const length = 32;

  Uint8List? _bytes;

  bool get isDestroyed => _bytes == null;

  Uint8List get bytes {
    final b = _bytes;
    if (b == null) {
      throw StateError('Vault key was destroyed; the vault must be unlocked.');
    }
    return b;
  }

  /// Overwrites the key material. Called on lock.
  void destroy() {
    final b = _bytes;
    if (b == null) return;
    b.fillRange(0, b.length, 0);
    _bytes = null;
  }

  @override
  String toString() => 'VaultKey(${isDestroyed ? 'destroyed' : 'live'})';
}

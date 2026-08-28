import 'dart:async';


import 'package:uuid/uuid.dart';

import '../../core/crypto/record_codec.dart';
import '../../core/crypto/vault_key.dart';
import '../local/app_database.dart';
import '../models/vault_entry.dart';

/// What [VaultBloc] needs from storage.
///
/// An interface, not the concrete class, so widget tests can supply a fake
/// instead of opening a real database. drift leaves a pending timer that
/// `flutter_test` asserts on before teardown runs, which wedges the whole test
/// file — and a widget test has no business touching sqlite anyway.
abstract interface class VaultDataSource {
  Stream<List<VaultEntry>> watchEntries(VaultKey key);
  Future<List<VaultEntry>> loadEntries(VaultKey key);
  Future<VaultEntry> create({
    required VaultKey key,
    required String site,
    required String username,
    required String password,
    String notes,
    String? totpSecret,
    DateTime? createdAt,
  });
  Future<VaultEntry> update({
    required VaultKey key,
    required VaultEntry entry,
  });
  Future<void> delete(String id);
  Future<int> importAll({
    required VaultKey key,
    required List<VaultEntry> entries,
  });
}

/// The only surface blocs use to reach vault data.
///
/// Encryption is not optional and not a layer above this one: rows go in
/// encrypted and come out decrypted, so there is no code path that can write a
/// plaintext password to disk. v1 stored plaintext while the settings screen
/// advertised encryption; making the repository the sole door closes that gap
/// structurally rather than by discipline.
class VaultRepository implements VaultDataSource {
  VaultRepository({required AppDatabase database, RecordCodec? codec})
    : _db = database,
      _codec = codec ?? RecordCodec();

  final AppDatabase _db;
  final RecordCodec _codec;
  final _uuid = const Uuid();

  /// Decrypted entries, refreshed whenever the underlying table changes.
  ///
  /// Requires the vault key, so this can only be subscribed to while unlocked.
  /// A row that fails to decrypt is dropped rather than throwing: one corrupt
  /// or foreign record must not make the whole vault unopenable.
  @override
  Stream<List<VaultEntry>> watchEntries(VaultKey key) {
    return _db.watchAll().asyncMap((rows) => _decryptAll(rows, key));
  }

  @override
  Future<List<VaultEntry>> loadEntries(VaultKey key) async =>
      _decryptAll(await _db.getAll(), key);

  Future<List<VaultEntry>> _decryptAll(List<Entry> rows, VaultKey key) async {
    final out = <VaultEntry>[];
    for (final row in rows) {
      final entry = await _tryDecrypt(row, key);
      if (entry != null) out.add(entry);
    }
    return out;
  }

  Future<VaultEntry?> _tryDecrypt(Entry row, VaultKey key) async {
    try {
      final payload = await _codec.decrypt(
        key: key,
        recordId: row.id,
        record: EncryptedRecord(
          ciphertext: row.ciphertext,
          nonce: row.nonce,
          schemaVersion: row.schemaVersion,
        ),
      );
      return VaultEntry.fromPayload(
        payload,
        id: row.id,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
    } on RecordDecryptionFailure {
      return null;
    }
  }

  /// How many stored rows the current key cannot open. Surfaced in settings so
  /// silent data loss is visible rather than looking like an empty vault.
  Future<int> undecryptableCount(VaultKey key) async {
    final rows = await _db.getAll();
    var bad = 0;
    for (final row in rows) {
      if (await _tryDecrypt(row, key) == null) bad++;
    }
    return bad;
  }

  @override
  Future<VaultEntry> create({
    required VaultKey key,
    required String site,
    required String username,
    required String password,
    String notes = '',
    String? totpSecret,
    DateTime? createdAt,
  }) async {
    final now = DateTime.now().toUtc();
    final entry = VaultEntry(
      id: _uuid.v4(),
      site: site,
      username: username,
      password: password,
      notes: notes,
      totpSecret: totpSecret,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
    await _write(key, entry, revision: 1);
    return entry;
  }

  @override
  Future<VaultEntry> update({
    required VaultKey key,
    required VaultEntry entry,
  }) async {
    final updated = entry.copyWith(updatedAt: DateTime.now().toUtc());
    final existing = await (_db.select(
      _db.entries,
    )..where((t) => t.id.equals(entry.id))).getSingleOrNull();

    await _write(key, updated, revision: (existing?.revision ?? 0) + 1);
    return updated;
  }

  @override
  Future<void> delete(String id) =>
      _db.softDelete(id, DateTime.now().toUtc());

  /// Bulk insert for imports. One transaction so a partial import cannot leave
  /// half a file behind.
  @override
  Future<int> importAll({
    required VaultKey key,
    required List<VaultEntry> entries,
  }) async {
    if (entries.isEmpty) return 0;
    final rows = <Entry>[];
    for (final e in entries) {
      rows.add(await _toRow(key, e, revision: 1));
    }
    await _db.upsertAll(rows);
    return rows.length;
  }

  Future<void> _write(
    VaultKey key,
    VaultEntry entry, {
    required int revision,
  }) async {
    await _db.upsert(await _toRow(key, entry, revision: revision));
  }

  Future<Entry> _toRow(
    VaultKey key,
    VaultEntry entry, {
    required int revision,
  }) async {
    final record = await _codec.encrypt(
      key: key,
      recordId: entry.id,
      payload: entry.toPayload(),
    );
    return Entry(
      id: entry.id,
      ciphertext: record.ciphertext,
      nonce: record.nonce,
      schemaVersion: record.schemaVersion,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      deletedAt: null,
      revision: revision,
      dirty: true,
    );
  }

  /// Re-encrypts every row under [newKey]. Needed after a recovery-code
  /// restore, when the local rows were written under a key this device no
  /// longer holds.
  Future<void> rekey({
    required VaultKey oldKey,
    required VaultKey newKey,
  }) async {
    final entries = await loadEntries(oldKey);
    final rows = <Entry>[];
    for (final e in entries) {
      rows.add(await _toRow(newKey, e, revision: 1));
    }
    await _db.upsertAll(rows);
  }

  Future<void> wipe() => _db.wipe();
}


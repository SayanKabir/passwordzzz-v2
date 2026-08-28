import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passwordzzz_v2/core/crypto/vault_key.dart';
import 'package:passwordzzz_v2/data/local/app_database.dart';
import 'package:passwordzzz_v2/data/models/vault_entry.dart';
import 'package:passwordzzz_v2/data/repository/vault_repository.dart';

VaultKey _key([int fill = 7]) =>
    VaultKey(Uint8List.fromList(List.filled(VaultKey.length, fill)));

VaultEntry _fixture(int i, DateTime now) => VaultEntry(
  id: 'id-$i',
  site: 'site$i.com',
  username: 'user$i',
  password: 'pw$i',
  createdAt: now,
  updatedAt: now,
);

void main() {
  late AppDatabase db;
  late VaultRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = VaultRepository(database: db);
  });

  tearDown(() => db.close());

  test('created entries round-trip through encryption', () async {
    final key = _key();
    await repo.create(
      key: key,
      site: 'github.com',
      username: 'sayan',
      password: 'hunter2',
    );

    final entries = await repo.loadEntries(key);
    expect(entries, hasLength(1));
    expect(entries.single.site, 'github.com');
    expect(entries.single.password, 'hunter2');
  });

  test('the stored row holds no plaintext', () async {
    // The property v1 failed: the DB file must not contain the password, the
    // site, or the username.
    final key = _key();
    await repo.create(
      key: key,
      site: 'github.com',
      username: 'sayan',
      password: 'hunter2',
    );

    final rows = await db.getAll();
    final blob = String.fromCharCodes(rows.single.ciphertext);
    expect(blob, isNot(contains('hunter2')));
    expect(blob, isNot(contains('github')));
    expect(blob, isNot(contains('sayan')));
  });

  test('a different key cannot read the vault', () async {
    await repo.create(
      key: _key(7),
      site: 'x.com',
      username: 'u',
      password: 'p',
    );

    // Undecryptable rows are dropped rather than thrown, so one bad record
    // cannot make the whole vault unopenable — but the count is reported.
    expect(await repo.loadEntries(_key(9)), isEmpty);
    expect(await repo.undecryptableCount(_key(9)), 1);
  });

  test('update bumps the revision and preserves createdAt', () async {
    final key = _key();
    final created = await repo.create(
      key: key,
      site: 'a.com',
      username: 'u',
      password: 'p',
    );

    final updated = await repo.update(
      key: key,
      entry: created.copyWith(password: 'p2'),
    );

    final rows = await db.getAll();
    expect(rows.single.revision, 2);
    expect(updated.createdAt, created.createdAt);
    expect((await repo.loadEntries(key)).single.password, 'p2');
  });

  test('delete writes a tombstone rather than removing the row', () async {
    // A hard delete lets a stale device resurrect the entry on the next sync.
    final key = _key();
    final e = await repo.create(
      key: key,
      site: 'a.com',
      username: 'u',
      password: 'p',
    );

    await repo.delete(e.id);

    expect(await repo.loadEntries(key), isEmpty);
    final all = await db.select(db.entries).get();
    expect(all, hasLength(1));
    expect(all.single.deletedAt, isNotNull);
  });

  test('watchEntries emits after each write', () async {
    final key = _key();
    final seen = <int>[];
    final sub = repo.watchEntries(key).listen((e) => seen.add(e.length));

    await repo.create(key: key, site: 'a.com', username: 'u', password: 'p');
    await repo.create(key: key, site: 'b.com', username: 'u', password: 'p');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await sub.cancel();

    expect(seen.last, 2);
  });

  test('importAll writes every entry', () async {
    final key = _key();
    final now = DateTime.now().toUtc();

    final count = await repo.importAll(
      key: key,
      entries: List.generate(50, (i) => _fixture(i, now)),
    );

    expect(count, 50);
    expect(await repo.loadEntries(key), hasLength(50));
  });

  test('rekey re-encrypts every row under the new key', () async {
    // The recovery-restore path: rows were written under a key this device no
    // longer holds.
    final oldKey = _key(7);
    final newKey = _key(9);
    await repo.create(
      key: oldKey,
      site: 'a.com',
      username: 'u',
      password: 'p',
    );

    await repo.rekey(oldKey: oldKey, newKey: newKey);

    final reread = await repo.loadEntries(newKey);
    expect(reread, hasLength(1));
    expect(reread.single.password, 'p');
    expect(await repo.loadEntries(oldKey), isEmpty);
  });
}

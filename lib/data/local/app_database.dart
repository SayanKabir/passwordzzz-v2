import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Encrypted vault records.
///
/// Only the ciphertext and sync bookkeeping are stored. There is no `site` or
/// `username` column: v1 kept both in plaintext alongside a plaintext password,
/// so anyone with the database file learned the whole account list.
class Entries extends Table {
  /// Client-generated UUID, so entries created offline sync without a
  /// server round-trip to allocate an id.
  TextColumn get id => text()();

  BlobColumn get ciphertext => blob()();
  BlobColumn get nonce => blob()();
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Tombstone. Rows are soft-deleted so the deletion itself can sync;
  /// a hard delete would let a stale device resurrect the entry.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Bumped on every local write; used for conflict resolution in Phase 3.
  IntColumn get revision => integer().withDefault(const Constant(1))();

  /// True when the row has local changes not yet pushed.
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Entries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'passwordzzz'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // Enforced per-connection, not once at creation.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Live view of every non-deleted row, newest first.
  Stream<List<Entry>> watchAll() {
    return (select(entries)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<List<Entry>> getAll() {
    return (select(entries)..where((t) => t.deletedAt.isNull())).get();
  }

  Future<void> upsert(Entry entry) =>
      into(entries).insertOnConflictUpdate(entry);

  Future<void> upsertAll(List<Entry> rows) async {
    await batch((b) => b.insertAllOnConflictUpdate(entries, rows));
  }

  /// Soft delete, so the tombstone can sync.
  Future<void> softDelete(String id, DateTime at) {
    return (update(entries)..where((t) => t.id.equals(id))).write(
      EntriesCompanion(
        deletedAt: Value(at),
        updatedAt: Value(at),
        dirty: const Value(true),
      ),
    );
  }

  /// Wipes everything. Used when the vault key is lost and the local copy is
  /// unreadable, so stale ciphertext does not linger.
  Future<void> wipe() => delete(entries).go();
}

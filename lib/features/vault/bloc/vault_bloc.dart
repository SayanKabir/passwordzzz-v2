import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/crypto/vault_key.dart';
import '../../../data/models/vault_entry.dart';
import '../../../data/repository/vault_repository.dart';
import 'vault_state.dart';

sealed class VaultEvent extends Equatable {
  const VaultEvent();

  @override
  List<Object?> get props => const [];
}

/// Subscribes to the decrypted entry stream. Fired when the vault unlocks.
final class VaultOpened extends VaultEvent {
  const VaultOpened(this.key);
  final VaultKey key;
}

final class _EntriesChanged extends VaultEvent {
  const _EntriesChanged(this.entries);
  final List<VaultEntry> entries;

  @override
  List<Object?> get props => [entries];
}

final class VaultSearchChanged extends VaultEvent {
  const VaultSearchChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

final class VaultEntrySaved extends VaultEvent {
  const VaultEntrySaved({
    required this.site,
    required this.username,
    required this.password,
    this.notes = '',
    this.existing,
  });

  final String site;
  final String username;
  final String password;
  final String notes;

  /// Null when creating.
  final VaultEntry? existing;

  @override
  List<Object?> get props => [site, username, notes, existing];
}

final class VaultEntryDeleted extends VaultEvent {
  const VaultEntryDeleted(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

final class VaultEntriesImported extends VaultEvent {
  const VaultEntriesImported(this.entries);
  final List<VaultEntry> entries;

  @override
  List<Object?> get props => [entries];
}

/// Owns the decrypted entry list.
///
/// The vault key arrives with [VaultOpened] rather than being held from
/// construction, so this bloc cannot outlive an unlock: when [AppLockCubit]
/// locks and zeroes the key, the next repository call fails loudly instead of
/// operating on a stale key.
class VaultBloc extends Bloc<VaultEvent, VaultState> {
  VaultBloc(this._repository) : super(const VaultLoading()) {
    on<VaultOpened>(_onOpened);
    on<_EntriesChanged>(_onEntriesChanged);

    // Search is restartable: only the latest query is processed, so holding a
    // key down does not queue a filter pass per character.
    on<VaultSearchChanged>(_onSearchChanged, transformer: restartable());

    // Writes are sequential so two rapid saves cannot interleave a read and a
    // write of the same revision.
    on<VaultEntrySaved>(_onSaved, transformer: sequential());
    on<VaultEntryDeleted>(_onDeleted, transformer: sequential());
    on<VaultEntriesImported>(_onImported, transformer: sequential());
  }

  final VaultDataSource _repository;
  VaultKey? _key;
  StreamSubscription<List<VaultEntry>>? _sub;

  Future<void> _onOpened(VaultOpened event, Emitter<VaultState> emit) async {
    _key = event.key;
    await _sub?.cancel();
    _sub = _repository
        .watchEntries(event.key)
        .listen((entries) => add(_EntriesChanged(entries)));
  }

  void _onEntriesChanged(_EntriesChanged event, Emitter<VaultState> emit) {
    final current = state;
    emit(
      VaultReady(
        all: event.entries,
        query: current is VaultReady ? current.query : '',
        undecryptable: current is VaultReady ? current.undecryptable : 0,
      ),
    );
  }

  void _onSearchChanged(VaultSearchChanged event, Emitter<VaultState> emit) {
    final current = state;
    if (current is! VaultReady) return;
    emit(
      VaultReady(
        all: current.all,
        query: event.query,
        undecryptable: current.undecryptable,
      ),
    );
  }

  Future<void> _onSaved(VaultEntrySaved event, Emitter<VaultState> emit) async {
    final key = _key;
    if (key == null) return emit(const VaultFailure('The vault is locked.'));

    try {
      if (event.existing == null) {
        await _repository.create(
          key: key,
          site: event.site,
          username: event.username,
          password: event.password,
          notes: event.notes,
        );
      } else {
        await _repository.update(
          key: key,
          entry: event.existing!.copyWith(
            site: event.site,
            username: event.username,
            password: event.password,
            notes: event.notes,
          ),
        );
      }
      // The drift stream pushes the new list; no manual refresh needed.
    } catch (e) {
      emit(VaultFailure('Could not save: $e'));
    }
  }

  Future<void> _onDeleted(
    VaultEntryDeleted event,
    Emitter<VaultState> emit,
  ) async {
    try {
      await _repository.delete(event.id);
    } catch (e) {
      emit(VaultFailure('Could not delete: $e'));
    }
  }

  Future<void> _onImported(
    VaultEntriesImported event,
    Emitter<VaultState> emit,
  ) async {
    final key = _key;
    if (key == null) return emit(const VaultFailure('The vault is locked.'));
    try {
      await _repository.importAll(key: key, entries: event.entries);
    } catch (e) {
      emit(VaultFailure('Could not import: $e'));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _key = null;
    return super.close();
  }
}

import 'package:equatable/equatable.dart';

import '../../../data/models/vault_entry.dart';

sealed class VaultState extends Equatable {
  const VaultState();

  @override
  List<Object?> get props => const [];
}

final class VaultLoading extends VaultState {
  const VaultLoading();
}

final class VaultReady extends VaultState {
  const VaultReady({
    required this.all,
    required this.query,
    this.undecryptable = 0,
  });

  final List<VaultEntry> all;
  final String query;

  /// Rows the current key cannot open. Surfaced rather than hidden, so a
  /// partially-unreadable vault does not look like an empty one.
  final int undecryptable;

  /// Filtered view. Computed here rather than in the widget so the list is not
  /// re-filtered on every rebuild.
  List<VaultEntry> get visible =>
      query.isEmpty ? all : all.where((e) => e.matches(query)).toList();

  bool get isEmpty => all.isEmpty;

  @override
  List<Object?> get props => [all, query, undecryptable];
}

final class VaultFailure extends VaultState {
  const VaultFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

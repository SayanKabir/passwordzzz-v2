import 'package:equatable/equatable.dart';

/// A decrypted vault entry, as the UI sees it.
///
/// Everything except [id] and the timestamps lives inside the encrypted
/// payload — site and username included. The server, and anyone reading the
/// database file, learns only that an entry exists and when it changed.
class VaultEntry extends Equatable {
  const VaultEntry({
    required this.id,
    required this.site,
    required this.username,
    required this.password,
    this.notes = '',
    this.totpSecret,
    this.favourite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String site;
  final String username;
  final String password;
  final String notes;
  final String? totpSecret;
  final bool favourite;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Display name derived from the site: `github.com` -> `Github`.
  ///
  /// v1 did `kSite.split('.')[0]` then indexed `[0]`, which threw on an empty
  /// string or one starting with a dot. Guarded here instead.
  String get displayName {
    final trimmed = site.trim();
    if (trimmed.isEmpty) return 'Untitled';
    final head = trimmed.split('.').firstWhere(
      (p) => p.isNotEmpty,
      orElse: () => trimmed,
    );
    if (head.isEmpty) return 'Untitled';
    return head[0].toUpperCase() + head.substring(1);
  }

  /// Fallback avatar letter when no icon is available.
  String get initial {
    final n = displayName;
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return site.toLowerCase().contains(q) ||
        username.toLowerCase().contains(q) ||
        notes.toLowerCase().contains(q);
  }

  /// The encrypted payload. Keys are short because every byte is stored and
  /// synced for every record.
  Map<String, dynamic> toPayload() => {
    's': site,
    'u': username,
    'p': password,
    if (notes.isNotEmpty) 'n': notes,
    if (totpSecret != null) 't': totpSecret,
    if (favourite) 'f': true,
  };

  factory VaultEntry.fromPayload(
    Map<String, dynamic> payload, {
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) => VaultEntry(
    id: id,
    site: payload['s'] as String? ?? '',
    username: payload['u'] as String? ?? '',
    password: payload['p'] as String? ?? '',
    notes: payload['n'] as String? ?? '',
    totpSecret: payload['t'] as String?,
    favourite: payload['f'] as bool? ?? false,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  VaultEntry copyWith({
    String? site,
    String? username,
    String? password,
    String? notes,
    String? totpSecret,
    bool? favourite,
    DateTime? updatedAt,
  }) => VaultEntry(
    id: id,
    site: site ?? this.site,
    username: username ?? this.username,
    password: password ?? this.password,
    notes: notes ?? this.notes,
    totpSecret: totpSecret ?? this.totpSecret,
    favourite: favourite ?? this.favourite,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  /// [password] is deliberately excluded so it cannot reach a log through a
  /// state dump or an equality-driven toString.
  @override
  List<Object?> get props => [
    id,
    site,
    username,
    notes,
    totpSecret,
    favourite,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() => 'VaultEntry($id, $site, $username)';
}

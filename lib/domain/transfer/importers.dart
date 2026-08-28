import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../data/models/vault_entry.dart';
import 'csv.dart';

/// Where an import came from. Used to pick a column mapping.
enum ImportFormat {
  /// Passwordzzz v1: a JSON array of {site, user, password}.
  passwordzzzV1,

  /// Chrome, Edge, Brave: name,url,username,password,note
  chromium,

  /// Bitwarden's unencrypted JSON export.
  bitwardenJson,

  /// Bitwarden CSV, and LastPass/1Password's close variants.
  genericCsv,
}

class ImportResult {
  const ImportResult({
    required this.entries,
    required this.skipped,
    required this.warnings,
  });

  final List<VaultEntry> entries;

  /// Rows that parsed but carried no password — usually secure notes or
  /// payment cards from another manager's export.
  final int skipped;

  final List<String> warnings;

  bool get isEmpty => entries.isEmpty;
}

class ImportFailure implements Exception {
  const ImportFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Parses an export from another password manager into vault entries.
///
/// Nothing is written by this class — it returns candidates for the caller to
/// encrypt and store. Import is the one path where a plaintext password file
/// legitimately exists, so it stays as short-lived and as narrow as possible.
class VaultImporter {
  VaultImporter({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  /// Guesses the format so the user does not have to know what their old
  /// manager called its export.
  static ImportFormat detect(String content) {
    final trimmed = content.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      if (trimmed.contains('"encrypted"') || trimmed.contains('"items"')) {
        return ImportFormat.bitwardenJson;
      }
      return ImportFormat.passwordzzzV1;
    }
    final header = parseCsv(content).firstOrNull?.map((h) => h.toLowerCase());
    if (header != null && header.contains('url') && header.contains('name')) {
      return ImportFormat.chromium;
    }
    return ImportFormat.genericCsv;
  }

  ImportResult parse(String content, {ImportFormat? format}) {
    final f = format ?? detect(content);
    return switch (f) {
      ImportFormat.passwordzzzV1 => _parseV1(content),
      ImportFormat.bitwardenJson => _parseBitwarden(content),
      ImportFormat.chromium ||
      ImportFormat.genericCsv => _parseCsv(content),
    };
  }

  ImportResult _parseV1(String content) {
    final warnings = <String>[];
    late final dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException catch (e) {
      throw ImportFailure('That file is not valid JSON (${e.message}).');
    }

    // v1 wrote either a bare array or {"passwords": [...]}.
    final list = decoded is List
        ? decoded
        : (decoded is Map ? decoded['passwords'] : null);
    if (list is! List) {
      throw ImportFailure('No password list found in that file.');
    }

    final entries = <VaultEntry>[];
    var skipped = 0;
    for (final raw in list) {
      if (raw is! Map) {
        skipped++;
        continue;
      }
      // v1's column names, plus the capitalised model field names it also used.
      final site = _str(raw, ['site', 'Site']);
      final user = _str(raw, ['user', 'Username', 'username']);
      final pass = _str(raw, ['password', 'Password_secured', 'Password']);
      if (pass.isEmpty) {
        skipped++;
        continue;
      }
      entries.add(_entry(site: site, username: user, password: pass));
    }

    if (entries.isEmpty && skipped > 0) {
      warnings.add('No rows carried a password.');
    }
    return ImportResult(
      entries: entries,
      skipped: skipped,
      warnings: warnings,
    );
  }

  ImportResult _parseBitwarden(String content) {
    late final dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException catch (e) {
      throw ImportFailure('That file is not valid JSON (${e.message}).');
    }
    if (decoded is! Map) throw ImportFailure('Unexpected Bitwarden export.');

    if (decoded['encrypted'] == true) {
      throw const ImportFailure(
        'That Bitwarden export is encrypted. Re-export it with the '
        '"unencrypted" option, import it here, then delete the file.',
      );
    }

    final items = decoded['items'];
    if (items is! List) throw ImportFailure('No items found in that export.');

    final entries = <VaultEntry>[];
    var skipped = 0;
    for (final item in items) {
      if (item is! Map) {
        skipped++;
        continue;
      }
      final login = item['login'];
      if (login is! Map || (login['password'] as String?)?.isEmpty != false) {
        // Secure notes, cards, and identities have no password to store.
        skipped++;
        continue;
      }
      final uris = login['uris'];
      final uri = uris is List && uris.isNotEmpty && uris.first is Map
          ? (uris.first as Map)['uri'] as String? ?? ''
          : '';
      entries.add(
        _entry(
          site: uri.isNotEmpty ? uri : (item['name'] as String? ?? ''),
          username: login['username'] as String? ?? '',
          password: login['password'] as String,
          notes: item['notes'] as String? ?? '',
          totp: login['totp'] as String?,
        ),
      );
    }
    return ImportResult(entries: entries, skipped: skipped, warnings: const []);
  }

  ImportResult _parseCsv(String content) {
    final rows = parseCsv(content);
    if (rows.isEmpty) throw const ImportFailure('That file is empty.');

    final header = rows.first.map((h) => h.trim().toLowerCase()).toList();

    // Column names differ per manager; match on any known alias rather than
    // requiring one exact layout. Aliases are tried in preference order, not
    // header order — Chromium exports lead with `name` (a display label) and
    // carry the real address in `url`, so scanning the header first would pick
    // the label and lose the URL that autofill matching depends on.
    int find(List<String> aliases) {
      for (final alias in aliases) {
        final i = header.indexOf(alias);
        if (i >= 0) return i;
      }
      return -1;
    }

    final passIdx = find(['password', 'login_password', 'pass']);
    if (passIdx < 0) {
      throw const ImportFailure(
        'No password column found. Expected a header row containing '
        '"password".',
      );
    }
    final siteIdx = find(['url', 'login_uri', 'uri', 'website', 'site', 'name', 'title']);
    final userIdx = find(['username', 'login_username', 'user', 'email', 'login']);
    final noteIdx = find(['note', 'notes', 'comments']);
    final totpIdx = find(['totp', 'otpauth', 'login_totp']);

    final entries = <VaultEntry>[];
    var skipped = 0;
    for (final row in rows.skip(1)) {
      String cell(int idx) =>
          idx >= 0 && idx < row.length ? row[idx].trim() : '';

      final pass = cell(passIdx);
      if (pass.isEmpty) {
        skipped++;
        continue;
      }
      entries.add(
        _entry(
          site: cell(siteIdx),
          username: cell(userIdx),
          password: pass,
          notes: cell(noteIdx),
          totp: cell(totpIdx).isEmpty ? null : cell(totpIdx),
        ),
      );
    }
    return ImportResult(entries: entries, skipped: skipped, warnings: const []);
  }

  static String _str(Map raw, List<String> keys) {
    for (final k in keys) {
      final v = raw[k];
      if (v != null) return v.toString();
    }
    return '';
  }

  VaultEntry _entry({
    required String site,
    required String username,
    required String password,
    String notes = '',
    String? totp,
  }) {
    final now = DateTime.now().toUtc();
    return VaultEntry(
      id: _uuid.v4(),
      site: site,
      username: username,
      password: password,
      notes: notes,
      totpSecret: (totp?.isEmpty ?? true) ? null : totp,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Writes a plaintext CSV that other managers can read.
///
/// Deliberately unencrypted and deliberately blunt about it: the file is only
/// useful to another manager if it is readable, so the safety lives in the
/// warning the UI shows and in the caller deleting the file afterwards.
String exportToCsv(List<VaultEntry> entries) {
  final rows = <List<String>>[
    ['name', 'url', 'username', 'password', 'note', 'totp'],
    for (final e in entries)
      [
        e.displayName,
        e.site,
        e.username,
        e.password,
        e.notes,
        e.totpSecret ?? '',
      ],
  ];
  return toCsv(rows);
}

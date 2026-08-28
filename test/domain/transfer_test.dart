import 'package:flutter_test/flutter_test.dart';
import 'package:passwordzzz_v2/data/models/vault_entry.dart';
import 'package:passwordzzz_v2/domain/transfer/csv.dart';
import 'package:passwordzzz_v2/domain/transfer/importers.dart';

void main() {
  group('CSV parsing', () {
    test('handles a password containing a comma', () {
      // Splitting on commas would turn this into two fields and silently
      // truncate the password — an import that looks fine until login fails.
      final rows = parseCsv('url,username,password\nx.com,me,"a,b,c"');
      expect(rows[1][2], 'a,b,c');
    });

    test('handles escaped quotes', () {
      final rows = parseCsv('password\n"he said ""hi"""');
      expect(rows[1][0], 'he said "hi"');
    });

    test('handles a newline inside a quoted note', () {
      final rows = parseCsv('note\n"line one\nline two"');
      expect(rows, hasLength(2));
      expect(rows[1][0], 'line one\nline two');
    });

    test('treats CRLF as one row break', () {
      final rows = parseCsv('a,b\r\n1,2\r\n3,4');
      expect(rows, hasLength(3));
      expect(rows[2], ['3', '4']);
    });

    test('strips a UTF-8 BOM', () {
      final rows = parseCsv('﻿url,password\nx.com,pw');
      expect(rows.first.first, 'url');
    });

    test('round-trips awkward values', () {
      const nasty = ['a,b', 'he said "hi"', 'line\nbreak', 'plain'];
      final out = parseCsv(toCsv([nasty]));
      expect(out.first, nasty);
    });
  });

  group('format detection', () {
    test('spots Bitwarden JSON', () {
      expect(
        VaultImporter.detect('{"encrypted":false,"items":[]}'),
        ImportFormat.bitwardenJson,
      );
    });

    test('spots a v1 JSON array', () {
      expect(
        VaultImporter.detect('[{"site":"x.com"}]'),
        ImportFormat.passwordzzzV1,
      );
    });

    test('spots a Chromium CSV', () {
      expect(
        VaultImporter.detect('name,url,username,password,note\n'),
        ImportFormat.chromium,
      );
    });
  });

  group('Passwordzzz v1 import', () {
    final importer = VaultImporter();

    test('reads v1 rows, including its capitalised field names', () {
      const json = '''
      [
        {"site":"github.com","user":"sayan","password":"pw1"},
        {"Site":"bank.in","Username":"s2","Password_secured":"pw2"}
      ]''';
      final r = importer.parse(json, format: ImportFormat.passwordzzzV1);

      expect(r.entries, hasLength(2));
      expect(r.entries[0].site, 'github.com');
      expect(r.entries[0].password, 'pw1');
      expect(r.entries[1].username, 's2');
      expect(r.entries[1].password, 'pw2');
    });

    test('skips rows with no password rather than importing blanks', () {
      const json = '[{"site":"x.com","user":"a","password":""}]';
      final r = importer.parse(json, format: ImportFormat.passwordzzzV1);

      expect(r.entries, isEmpty);
      expect(r.skipped, 1);
      expect(r.warnings, isNotEmpty);
    });

    test('reports malformed JSON instead of throwing a raw FormatException', () {
      expect(
        () => importer.parse('{not json', format: ImportFormat.passwordzzzV1),
        throwsA(isA<ImportFailure>()),
      );
    });
  });

  group('Bitwarden import', () {
    final importer = VaultImporter();

    test('refuses an encrypted export with an actionable message', () {
      expect(
        () => importer.parse('{"encrypted":true,"items":[]}'),
        throwsA(
          isA<ImportFailure>().having(
            (e) => e.message,
            'message',
            contains('unencrypted'),
          ),
        ),
      );
    });

    test('imports logins and skips notes and cards', () {
      const json = '''
      {"encrypted":false,"items":[
        {"name":"GitHub","notes":"work",
         "login":{"username":"sayan","password":"pw","totp":"JBSWY3DP",
                  "uris":[{"uri":"https://github.com"}]}},
        {"name":"A note","notes":"no login here"},
        {"name":"Card","card":{"number":"4111"}}
      ]}''';
      final r = importer.parse(json);

      expect(r.entries, hasLength(1));
      expect(r.entries.single.site, 'https://github.com');
      expect(r.entries.single.totpSecret, 'JBSWY3DP');
      expect(r.skipped, 2);
    });
  });

  group('CSV import', () {
    final importer = VaultImporter();

    test('maps Chromium columns', () {
      const csv =
          'name,url,username,password,note\n'
          'GitHub,https://github.com,sayan,"pw,with,commas",a note';
      final r = importer.parse(csv);

      expect(r.entries.single.site, 'https://github.com');
      expect(r.entries.single.username, 'sayan');
      expect(r.entries.single.password, 'pw,with,commas');
      expect(r.entries.single.notes, 'a note');
    });

    test('maps LastPass-style aliases', () {
      const csv = 'uri,login_username,login_password\nx.com,me,secret';
      final r = importer.parse(csv, format: ImportFormat.genericCsv);

      expect(r.entries.single.site, 'x.com');
      expect(r.entries.single.username, 'me');
      expect(r.entries.single.password, 'secret');
    });

    test('rejects a file with no password column', () {
      expect(
        () => importer.parse('url,username\nx.com,me'),
        throwsA(
          isA<ImportFailure>().having(
            (e) => e.message,
            'message',
            contains('password'),
          ),
        ),
      );
    });
  });

  group('export', () {
    test('produces a header plus one row per entry, re-importable', () {
      final now = DateTime.utc(2026);
      final entries = [
        VaultEntry(
          id: '1',
          site: 'github.com',
          username: 'sayan',
          password: 'pw,with,comma',
          notes: 'line\nbreak',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final csv = exportToCsv(entries);
      final back = VaultImporter().parse(csv);

      // The round trip is the real assertion: an export another manager cannot
      // read is worse than no export.
      expect(back.entries.single.password, 'pw,with,comma');
      expect(back.entries.single.notes, 'line\nbreak');
      expect(back.entries.single.username, 'sayan');
    });
  });

  group('VaultEntry.displayName', () {
    test('does not throw on the strings that crashed v1', () {
      // v1 did site.split('.')[0][0] — empty and dot-leading both threw.
      for (final s in ['', '.', '...', '   ']) {
        final e = VaultEntry(
          id: 'x',
          site: s,
          username: '',
          password: 'p',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        );
        expect(e.displayName, isNotEmpty, reason: 'site=<$s>');
        expect(e.initial, isNotEmpty);
      }
    });

    test('capitalises the first label', () {
      final e = VaultEntry(
        id: 'x',
        site: 'github.com',
        username: '',
        password: 'p',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      expect(e.displayName, 'Github');
    });
  });

  test('a password never appears in VaultEntry.toString or props', () {
    final e = VaultEntry(
      id: 'x',
      site: 's',
      username: 'u',
      password: 'super-secret',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    expect(e.toString(), isNot(contains('super-secret')));
    expect(e.props.join(), isNot(contains('super-secret')));
  });
}

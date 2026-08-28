/// A CSV parser that handles quoting, embedded commas, embedded newlines, and
/// escaped quotes.
///
/// Password exports routinely contain all four — a note with a line break, a
/// password containing a comma, a site name with an apostrophe. Splitting on
/// commas silently corrupts those rows, and a corrupted password looks like a
/// successful import right up until the user tries to log in somewhere.
List<List<String>> parseCsv(String input) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;

  // Strip a UTF-8 BOM; Excel and several managers emit one.
  if (input.isNotEmpty && input.codeUnitAt(0) == 0xFEFF) i = 1;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    // Skip blank trailing lines rather than emitting an empty record.
    if (row.length > 1 || row.first.isNotEmpty) rows.add(row);
    row = <String>[];
  }

  while (i < input.length) {
    final c = input[i];

    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < input.length && input[i + 1] == '"') {
          field.write('"'); // escaped quote
          i += 2;
          continue;
        }
        inQuotes = false;
        i++;
        continue;
      }
      field.write(c);
      i++;
      continue;
    }

    switch (c) {
      case '"':
        inQuotes = true;
      case ',':
        endField();
      case '\r':
        // CRLF must not produce an empty row between records.
        if (i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        endRow();
      case '\n':
        endRow();
      default:
        field.write(c);
    }
    i++;
  }

  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

/// Quotes a field only when it needs it.
String csvEscape(String value) {
  if (!value.contains(RegExp(r'[",\r\n]'))) return value;
  return '"${value.replaceAll('"', '""')}"';
}

String toCsv(List<List<String>> rows) =>
    rows.map((r) => r.map(csvEscape).join(',')).join('\r\n');

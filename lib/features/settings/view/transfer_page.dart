import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/transfer/importers.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/motion.dart';
import '../../../ui/widgets/glass.dart';
import '../../vault/bloc/vault_bloc.dart';
import '../../vault/bloc/vault_state.dart';

/// Import from other managers, and export for them.
///
/// Import is where a plaintext password file legitimately exists, so the flow
/// keeps it as short-lived as possible: read, parse, encrypt, and tell the user
/// to delete the source.
class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  String? _status;
  bool _busy = false;

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _status = null;
    });

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) {
        setState(() => _busy = false);
        return;
      }

      final file = picked.files.single;
      final bytes = file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) {
        setState(() {
          _busy = false;
          _status = 'Could not read that file.';
        });
        return;
      }

      final content = String.fromCharCodes(bytes);
      final format = VaultImporter.detect(content);
      final result = VaultImporter().parse(content, format: format);

      if (result.isEmpty) {
        setState(() {
          _busy = false;
          _status = 'No passwords found in ${file.name}.';
        });
        return;
      }

      if (!mounted) return;
      context.read<VaultBloc>().add(VaultEntriesImported(result.entries));

      setState(() {
        _busy = false;
        _status =
            'Imported ${result.entries.length} '
            '${result.entries.length == 1 ? "password" : "passwords"} '
            'from ${_label(format)}.'
            '${result.skipped > 0 ? " Skipped ${result.skipped} row(s) with no password." : ""}'
            '\n\nDelete the source file now — it holds your passwords in the '
            'clear.';
      });
    } on ImportFailure catch (e) {
      setState(() {
        _busy = false;
        _status = e.message;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _status = 'Import failed: $e';
      });
    }
  }

  Future<void> _export() async {
    final state = context.read<VaultBloc>().state;
    if (state is! VaultReady || state.all.isEmpty) {
      setState(() => _status = 'Nothing to export yet.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export as plain text?'),
        content: const Text(
          'The exported file contains every password unencrypted, so other '
          'managers can read it. Anything that can read your files can read '
          'it too.\n\nShare it straight into the app you are moving to, then '
          'delete it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final csv = exportToCsv(state.all);
    // Written to the cache dir, not Documents: the OS reclaims it, so a
    // forgotten export does not sit in the user's file manager forever.
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/passwordzzz-export.csv');
    await file.writeAsString(csv, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Passwordzzz export',
    );

    if (!mounted) return;
    setState(() => _status = 'Exported ${state.all.length} passwords.');
  }

  static String _label(ImportFormat f) => switch (f) {
    ImportFormat.passwordzzzV1 => 'Passwordzzz v1',
    ImportFormat.bitwardenJson => 'Bitwarden',
    ImportFormat.chromium => 'Chrome',
    ImportFormat.genericCsv => 'CSV',
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Import & export')),
      body: ListView(
        padding: const EdgeInsets.all(Space.lg),
        children: [
          Text(
            'Supported: Passwordzzz v1 (JSON), Bitwarden (unencrypted JSON), '
            'Chrome/Edge/Brave, LastPass, 1Password, and most CSV exports.',
            style: text.bodySmall?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: Space.lg),
          FauxGlass(
            borderRadius: BorderRadius.circular(Radii.lg),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.download_outlined, color: c.brand),
                  title: const Text('Import from a file'),
                  subtitle: const Text('Format is detected automatically'),
                  onTap: _busy ? null : _import,
                ),
                Divider(height: 1, color: c.border),
                ListTile(
                  leading: Icon(Icons.upload_outlined, color: c.brand),
                  title: const Text('Export as CSV'),
                  subtitle: const Text('Unencrypted — for moving to another app'),
                  onTap: _busy ? null : _export,
                ),
              ],
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: Space.xl),
            const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          ],
          if (_status != null) ...[
            const SizedBox(height: Space.lg),
            FauxGlass(
              borderRadius: BorderRadius.circular(Radii.md),
              child: Padding(
                padding: const EdgeInsets.all(Space.lg),
                child: Text(_status!, style: text.bodySmall),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

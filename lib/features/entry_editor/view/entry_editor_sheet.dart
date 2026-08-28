import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/vault_entry.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/motion.dart';
import '../../../ui/widgets/glass.dart';
import '../../vault/bloc/vault_bloc.dart';

/// Create/edit sheet.
///
/// Deliberately plain for now — the generator, strength meter, and URL
/// autocomplete arrive in Phases 5 and 7. What matters here is that saving
/// works and the value goes through the repository, so it is encrypted.
class EntryEditorSheet extends StatefulWidget {
  const EntryEditorSheet({super.key, this.existing});

  final VaultEntry? existing;

  static Future<void> show(BuildContext context, {VaultEntry? existing}) {
    final bloc = context.read<VaultBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // The sheet takes the screen's one blur budget while it is open, so the
      // app bar behind it drops to the cheap glass treatment.
      builder: (_) => GlassScope(
        blurAvailable: false,
        child: BlocProvider.value(
          value: bloc,
          child: EntryEditorSheet(existing: existing),
        ),
      ),
    );
  }

  @override
  State<EntryEditorSheet> createState() => _EntryEditorSheetState();
}

class _EntryEditorSheetState extends State<EntryEditorSheet> {
  late final _site = TextEditingController(text: widget.existing?.site ?? '');
  late final _user = TextEditingController(
    text: widget.existing?.username ?? '',
  );
  late final _pass = TextEditingController(
    text: widget.existing?.password ?? '',
  );
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');

  final _form = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    // v1 built its controller inside build(), which made a new one every frame
    // and broke the cursor. Owning them in State fixes that by construction.
    _site.dispose();
    _user.dispose();
    _pass.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    context.read<VaultBloc>().add(
      VaultEntrySaved(
        site: _site.text.trim(),
        username: _user.text.trim(),
        password: _pass.text,
        notes: _notes.text.trim(),
        existing: widget.existing,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final editing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: Space.lg,
        right: Space.lg,
        top: Space.sm,
        // Keeps the save button above the keyboard.
        bottom: MediaQuery.viewInsetsOf(context).bottom + Space.lg,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'Edit password' : 'New password',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: Space.lg),
            TextFormField(
              controller: _site,
              autofocus: !editing,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Website or app',
                prefixIcon: Icon(Icons.language_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _user,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                hintText: 'Username or email',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _pass,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.key_outlined),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: Space.md),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: Space.lg),
            Row(
              children: [
                if (editing)
                  TextButton.icon(
                    onPressed: () {
                      context.read<VaultBloc>().add(
                        VaultEntryDeleted(widget.existing!.id),
                      );
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.delete_outline, color: c.danger),
                    label: Text('Delete', style: TextStyle(color: c.danger)),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(editing ? 'Save' : 'Add'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(140, 48),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only detail view with copy actions.
class EntryDetailSheet extends StatelessWidget {
  const EntryDetailSheet({super.key, required this.entry});

  final VaultEntry entry;

  static Future<void> show(BuildContext context, VaultEntry entry) {
    final bloc = context.read<VaultBloc>();
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => GlassScope(
        blurAvailable: false,
        child: BlocProvider.value(
          value: bloc,
          child: EntryDetailSheet(entry: entry),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            entry.displayName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (entry.site.isNotEmpty)
            Text(
              entry.site,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: c.textSecondary),
            ),
          const SizedBox(height: Space.lg),
          _CopyField(label: 'Username', value: entry.username),
          const SizedBox(height: Space.sm),
          _CopyField(label: 'Password', value: entry.password, secret: true),
          if (entry.notes.isNotEmpty) ...[
            const SizedBox(height: Space.sm),
            _CopyField(label: 'Notes', value: entry.notes),
          ],
          const SizedBox(height: Space.lg),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              EntryEditorSheet.show(context, existing: entry);
            },
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class _CopyField extends StatefulWidget {
  const _CopyField({
    required this.label,
    required this.value,
    this.secret = false,
  });

  final String label;
  final String value;
  final bool secret;

  @override
  State<_CopyField> createState() => _CopyFieldState();
}

class _CopyFieldState extends State<_CopyField> {
  late bool _hidden = widget.secret;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (widget.value.isEmpty) return const SizedBox.shrink();

    return FauxGlass(
      borderRadius: BorderRadius.circular(Radii.md),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.sm, Space.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: c.textSecondary),
                  ),
                  Text(
                    _hidden ? '•' * widget.value.length.clamp(1, 20) : widget.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (widget.secret)
              IconButton(
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
              ),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${widget.label} copied')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

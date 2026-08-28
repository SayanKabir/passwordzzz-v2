import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/motion.dart';
import '../../../ui/widgets/glass.dart';
import '../../../ui/widgets/passwordzzz_mark.dart';
import '../../entry_editor/view/entry_editor_sheet.dart';
import '../../unlock/bloc/app_lock_cubit.dart';
import '../bloc/vault_bloc.dart';
import '../bloc/vault_state.dart';
import '../widgets/entry_row.dart';
import '../widgets/vault_empty_state.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  final _search = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _search.clear();
        context.read<VaultBloc>().add(const VaultSearchChanged(''));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,

      // The app bar owns this screen's single blur budget. Sheets wrap
      // themselves in GlassScope(blurAvailable: false) to take it.
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: BlurGlass(
          sigma: 20,
          tintOpacity: 0.68,
          showTopHighlight: false,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 58,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                child: Row(
                  children: [
                    if (_searching)
                      Expanded(
                        child: TextField(
                          controller: _search,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Search vault',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                          ),
                          onChanged: (v) => context.read<VaultBloc>().add(
                            VaultSearchChanged(v),
                          ),
                        ),
                      )
                    else
                      // The wordmark IS the settings affordance. No gear icon.
                      PasswordzzzWordmark(
                        onTap: () => context.push(Routes.settings),
                      ),
                    if (!_searching) const Spacer(),
                    IconButton(
                      tooltip: _searching ? 'Close search' : 'Search',
                      onPressed: _toggleSearch,
                      icon: Icon(
                        _searching ? Icons.close_rounded : Icons.search_rounded,
                        color: c.textSecondary,
                      ),
                    ),
                    if (!_searching)
                      IconButton(
                        tooltip: 'Lock vault',
                        onPressed: () => context.read<AppLockCubit>().lock(),
                        icon: Icon(Icons.lock_outline, color: c.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      body: BlocBuilder<VaultBloc, VaultState>(
        builder: (context, state) => switch (state) {
          VaultLoading() => const Center(
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          VaultFailure(message: final m) => Center(
            child: Padding(
              padding: const EdgeInsets.all(Space.xxl),
              child: Text(m, textAlign: TextAlign.center),
            ),
          ),
          VaultReady(isEmpty: true) => const VaultEmptyState(),
          VaultReady() => _EntryList(state: state),
        },
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GlassFab(
        label: 'New password',
        icon: Icons.add_rounded,
        onPressed: () => EntryEditorSheet.show(context),
      ),
    );
  }
}

class _EntryList extends StatelessWidget {
  const _EntryList({required this.state});

  final VaultReady state;

  @override
  Widget build(BuildContext context) {
    final visible = state.visible;
    final top = MediaQuery.paddingOf(context).top + 58 + Space.sm;

    if (visible.isEmpty) {
      return Center(
        child: Text(
          'Nothing matches "${state.query}".',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.of(context).textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      // Fixed extent makes scroll extent O(1) instead of measuring every row.
      itemExtent: kVaultRowExtent,
      padding: EdgeInsets.only(top: top, bottom: 120),
      physics: const BouncingScrollPhysics(),
      itemCount: visible.length,
      itemBuilder: (context, i) {
        final entry = visible[i];
        return EntryRow(
          entry: entry,
          onTap: () => EntryDetailSheet.show(context, entry),
          onLongPress: () => EntryEditorSheet.show(context, existing: entry),
        );
      },
    );
  }
}

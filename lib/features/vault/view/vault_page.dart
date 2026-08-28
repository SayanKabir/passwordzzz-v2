import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/motion.dart';
import '../../../ui/widgets/glass.dart';
import '../../../ui/widgets/passwordzzz_mark.dart';
import '../../unlock/bloc/app_lock_cubit.dart';
import '../widgets/vault_empty_state.dart';

class VaultPage extends StatelessWidget {
  const VaultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,

      // The app bar owns this screen's single blur budget. When a sheet opens
      // it wraps itself in a GlassScope(blurAvailable: false), which drops this
      // to the cheap treatment for the sheet's lifetime.
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
                    // The wordmark IS the settings affordance. No gear icon.
                    PasswordzzzWordmark(
                      onTap: () => context.push(Routes.settings),
                    ),
                    const Spacer(),
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

      // Phase 2 swaps this for a BlocBuilder<VaultBloc, VaultState> driving a
      // ListView.builder with itemExtent: kVaultRowExtent.
      body: const VaultEmptyState(),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GlassFab(
        label: 'New password',
        icon: Icons.add_rounded,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry editor lands in Phase 2.')),
          );
        },
      ),
    );
  }
}

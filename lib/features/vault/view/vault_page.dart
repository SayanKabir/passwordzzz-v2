import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app_router.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/motion.dart';
import '../../../ui/widgets/brand_logo.dart';
import '../../unlock/bloc/app_lock_cubit.dart';
import '../widgets/vault_empty_state.dart';

class VaultPage extends StatelessWidget {
  const VaultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      // A single blur surface, on the app bar only. v1 ran four simultaneous
      // BackdropFilters (app bar, search overlay, FAB, dialog); each one is a
      // full-screen GPU readback and together they were the main source of jank
      // on mid-range devices. Everywhere else uses AppColors.scrim instead.
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: Space.lg,
        title: const BrandLogo.wordmark(height: 26),
        actions: [
          IconButton(
            tooltip: 'Lock vault',
            onPressed: () => context.read<AppLockCubit>().lock(),
            icon: const Icon(Icons.lock_outline),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push(Routes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: Space.sm),
        ],
      ),

      // Phase 2 swaps this for a BlocBuilder<VaultBloc, VaultState> driving a
      // ListView.builder with itemExtent: kVaultRowExtent.
      body: const VaultEmptyState(),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry editor lands in Phase 2.')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New password'),
        backgroundColor: c.brand,
        foregroundColor: c.textOnBrand,
      ),
    );
  }
}

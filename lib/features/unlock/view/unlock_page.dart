import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ui/theme/app_colors.dart';
import '../../../ui/widgets/passwordzzz_mark.dart';
import '../../../ui/theme/motion.dart';
import '../bloc/app_lock_cubit.dart';
import '../bloc/app_lock_state.dart';

class UnlockPage extends StatelessWidget {
  const UnlockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: BlocBuilder<AppLockCubit, AppLockState>(
              builder: (context, state) {
                final busy = state is LockUnlocking;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BreathingPasswordzzzMark(size: 84),
                    const SizedBox(height: Space.xl),
                    Text(
                      'Passwordzzz',
                      style: text.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Space.sm),
                    Text(
                      'Your vault is locked.',
                      style: text.bodyMedium?.copyWith(color: c.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Space.huge),
                    AnimatedSwitcher(
                      duration: Motion.quick,
                      child: busy
                          ? const SizedBox(
                              height: 52,
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            )
                          : FilledButton.icon(
                              onPressed: () =>
                                  context.read<AppLockCubit>().unlock(),
                              icon: const Icon(Icons.fingerprint, size: 22),
                              label: const Text('Unlock'),
                            ),
                    ),
                    if (state is LockLocked && state.reason != null) ...[
                      const SizedBox(height: Space.lg),
                      Text(
                        state.reason!,
                        style: text.bodySmall?.copyWith(color: c.danger),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

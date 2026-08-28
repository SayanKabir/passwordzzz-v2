import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/motion.dart';
import '../../../ui/widgets/passwordzzz_mark.dart';
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
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: BlocBuilder<AppLockCubit, AppLockState>(
              builder: (context, state) {
                final copy = _copyFor(state);

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
                      copy.subtitle,
                      style: text.bodyMedium?.copyWith(color: c.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Space.huge),
                    AnimatedSwitcher(
                      duration: Motion.quick,
                      child: state is LockChecking || state is LockUnlocking
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
                              key: ValueKey(copy.action),
                              onPressed: () => _act(context, state),
                              icon: Icon(copy.icon, size: 22),
                              label: Text(copy.action),
                            ),
                    ),
                    if (copy.error != null) ...[
                      const SizedBox(height: Space.lg),
                      Text(
                        copy.error!,
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

  void _act(BuildContext context, AppLockState state) {
    final cubit = context.read<AppLockCubit>();
    if (state is LockUninitialized) {
      cubit.createVault();
    } else if (state is LockUnrecoverable) {
      // Recovery-code restore arrives in Phase 4.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recovery-code restore arrives in Phase 4.'),
        ),
      );
    } else {
      cubit.unlock();
    }
  }

  _Copy _copyFor(AppLockState state) => switch (state) {
    LockChecking() => const _Copy(
      subtitle: 'Checking this device…',
      action: 'Unlock',
      icon: Icons.fingerprint,
    ),
    LockUninitialized() => const _Copy(
      subtitle: 'Set up your vault. Its key is generated on this device and '
          'never leaves it.',
      action: 'Create vault',
      icon: Icons.shield_outlined,
    ),
    LockUnlocking() => const _Copy(
      subtitle: 'Waiting for you…',
      action: 'Unlock',
      icon: Icons.fingerprint,
    ),
    LockLocked(reason: final reason) => _Copy(
      subtitle: 'Your vault is locked.',
      action: 'Unlock',
      icon: Icons.fingerprint,
      error: reason,
    ),
    LockUnrecoverable(reason: final reason) => _Copy(
      subtitle: 'This device can no longer open your vault.',
      action: 'Restore with recovery code',
      icon: Icons.key_outlined,
      error: reason,
    ),
    LockUnlocked() => const _Copy(
      subtitle: 'Unlocked.',
      action: 'Unlock',
      icon: Icons.fingerprint,
    ),
  };
}

class _Copy {
  const _Copy({
    required this.subtitle,
    required this.action,
    required this.icon,
    this.error,
  });

  final String subtitle;
  final String action;
  final IconData icon;
  final String? error;
}

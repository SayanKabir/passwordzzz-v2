import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/motion.dart';
import '../bloc/theme_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.lg,
          vertical: Space.sm,
        ),
        children: [
          Text(
            'APPEARANCE',
            style: text.labelSmall?.copyWith(
              color: c.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: Space.sm),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              return SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {mode},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    context.read<ThemeCubit>().set(s.first),
              );
            },
          ),
          const SizedBox(height: Space.xl),

          // v1's settings page carried an "Encrypt Passwords" toggle that wrote
          // a pref nothing ever read, and a privacy policy stating passwords
          // were encrypted when they were stored in plaintext. Neither is
          // carried forward: encryption is not optional in v2, and no claim
          // goes on this screen until the code behind it is real.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Row(
                children: [
                  Icon(Icons.construction_outlined, color: c.textSecondary),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      'Security, sync, and autofill settings arrive with '
                      'Phases 1–6.',
                      style: text.bodySmall?.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
